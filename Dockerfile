FROM rust:1.73 as builder

ENV APP_USER app
ENV APP_HOME /app
RUN groupadd $APP_USER && useradd -m -g $APP_USER -l $APP_USER
RUN mkdir -p $APP_HOME/build && chown -R $APP_USER:$APP_USER $APP_HOME
WORKDIR $APP_HOME/build
USER $APP_USER

# build specific commit
RUN git clone https://github.com/junkurihara/doh-server/ . \
    && git checkout cdbc43a2ccbc964525075feab1d5056aed61783a && git reset --hard

RUN cargo install doh-proxy \
    && cp -p /usr/local/cargo/bin/doh-proxy $APP_HOME/
# RUN cargo build --release \
#     && cp -p target/release/doh-proxy $APP_HOME/

WORKDIR $APP_HOME

RUN rm -rf build


FROM debian:bookworm-slim

ENV APP_USER app
ENV APP_HOME /app
RUN groupadd $APP_USER && useradd -m -g $APP_USER -l $APP_USER
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

ENV LOCAL_PORT 3000

RUN apt-get update && apt-get upgrade && rm -rf /var/lib/apt/lists/*

# COPY --chown=0:0 --from=builder $APP_HOME/doh-proxy $APP_HOME/
COPY --chown=0:0 --from=builder /usr/local/cargo/bin/doh-proxy /usr/local/bin/doh-proxy
# COPY --chown=0:0 --from=builder $APP_HOME/doh-proxy /usr/local/bin/doh-proxy

EXPOSE $LOCAL_PORT/tcp $LOCAL_PORT/udp

ENTRYPOINT ["doh-proxy"]
CMD ["--allow-odoh-post", "-l", "0.0.0.0:3000"]

