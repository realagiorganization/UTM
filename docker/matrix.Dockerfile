ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

ARG RUST_TOOLCHAIN=stable
ARG TARGET=x86_64-unknown-linux-gnu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      build-essential \
      pkg-config \
      libssl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain "${RUST_TOOLCHAIN}" --profile minimal

ENV PATH=/root/.cargo/bin:${PATH}

RUN rustup target add "${TARGET}"

WORKDIR /workspace

COPY Scripting/agents_publisher /workspace/Scripting/agents_publisher

RUN cargo build --release --locked \
    --manifest-path /workspace/Scripting/agents_publisher/Cargo.toml \
    --target "${TARGET}"
