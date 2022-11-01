# syntax=docker/dockerfile:1

#Note we build on host plaftform and cross-compile to target arch
FROM --platform=$BUILDPLATFORM rust:latest as cross
ARG TARGETARCH
WORKDIR /app
COPY platform.sh .
RUN ./platform.sh # should write /.platform and /.compiler
RUN rustup component add rustfmt
RUN rustup target add $(cat /.platform)
RUN apt-get update && apt-get install -y unzip $(cat /.compiler)

COPY ["./metrics/Cargo.toml", "./metrics/Cargo.lock", "./"]
COPY .cargo/config .cargo/config
COPY ["./metrics/src", "./src"]

RUN mkdir src && echo "fn main() {}" > src/main.rs

RUN apt-get update && apt-get install libssl-dev
RUN cargo tree --target=$(cat /.platform) -i openssl-sys
RUN echo $OPENSSL_DIR
RUN touch src/main.rs && cargo build --release --target=$(cat /.platform)

FROM gcr.io/distroless/cc-debian11
COPY --from=cross /app/target/release/metrics /
CMD ["/metrics"]

# FROM rust:1.58 as build

# RUN echo "export PATH=/usr/local/cargo/bin:$PATH" >> /etc/profile

# WORKDIR /app



# RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo fetch

# COPY ["./metrics/src", "./src"]

# RUN touch src/main.rs && cargo build --release --offline

# FROM gcr.io/distroless/cc-debian11

# COPY --from=build /app/target/release/metrics /

# CMD ["/metrics"]
