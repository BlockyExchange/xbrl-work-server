# -------------------------------
# Stage 1: Builder
# -------------------------------
FROM docker.io/debian:bullseye-slim AS builder

# Install build dependencies:
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ocl-icd-opencl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up environment variables for rustup and cargo.
ENV RUSTUP_HOME=/rustup \
    CARGO_HOME=/cargo
ENV PATH=/cargo/bin:$PATH

# Install Rust toolchain non-interactively.
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# Clone the nano-work-server repository.
RUN git clone https://github.com/BlockyExchange/xbrl-work-server.git nano-work-server

# Change directory into the cloned repository.
WORKDIR /nano-work-server

# Build the project in release mode.
RUN cargo build --release

# -------------------------------
# Stage 2: Runtime using rocm/rocm-terminal
# -------------------------------
FROM docker.io/rocm/rocm-terminal:6.3.3

# Copy the built binary from the builder stage.
COPY --from=builder /nano-work-server/target/release/nano-work-server /usr/local/bin/nano-work-server

# Set ENTRYPOINT to use shell
ENTRYPOINT ["sh", "-c"]

# Inline CMD with conditional logic
CMD ["LISTEN_HOST=${LISTEN_HOST:-0.0.0.0}; LISTEN_PORT=${LISTEN_PORT:-7076}; OPTIONS=\"\"; if [ -n \"$CPU_THREADS\" ] && [ \"$CPU_THREADS\" -gt 0 ]; then OPTIONS=\"-c $CPU_THREADS\"; elif [ -n \"$GPU\" ]; then OPTIONS=\"-g $GPU -c 0\"; else OPTIONS=\"-c 0\"; fi; OPTIONS=\"$OPTIONS -l $LISTEN_HOST:$LISTEN_PORT\"; exec nano-work-server $OPTIONS"]
