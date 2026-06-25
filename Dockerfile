FROM rust:1.87-slim AS builder

WORKDIR /workdir
RUN apt-get update
RUN apt-get install -y git
RUN git clone https://github.com/asivery/qmldiff /workdir
RUN cargo build --release

FROM ubuntu:latest
RUN apt-get update
RUN apt-get install -y git
WORKDIR /workdir
COPY --from=builder /workdir/target/release/qmldiff /usr/bin/
COPY entrypoint.sh /workdir/
CMD ["/workdir/entrypoint.sh"]
