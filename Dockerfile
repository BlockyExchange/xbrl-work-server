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

# Copy the startup script into the image
COPY startup.sh /startup.sh

# Set the entrypoint to run the script with sh
ENTRYPOINT ["sh", "/startup.sh"]