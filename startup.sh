#!/bin/sh

# Set default values for LISTEN_HOST and LISTEN_PORT if not provided
LISTEN_HOST=${LISTEN_HOST:-0.0.0.0}
LISTEN_PORT=${LISTEN_PORT:-7076}
OPTIONS=""

# Build the options string based on CPU_THREADS or GPU
if [ -n "$CPU_THREADS" ] && [ "$CPU_THREADS" -gt 0 ]; then
    OPTIONS="-c $CPU_THREADS"
elif [ -n "$GPU" ]; then
    OPTIONS="-g $GPU -c 0"
else
    OPTIONS="-c 0"
fi

# Append the listen address
OPTIONS="$OPTIONS -l $LISTEN_HOST:$LISTEN_PORT"

# Add --gpu-local-work-size if GPU_LOCAL_WORK_SIZE is set
if [ -n "$GPU_LOCAL_WORK_SIZE" ]; then
    OPTIONS="$OPTIONS --gpu-local-work-size $GPU_LOCAL_WORK_SIZE"
fi

# Add --shuffle if SHUFFLE is "true" or "1"
if [ "$SHUFFLE" = "true" ] || [ "$SHUFFLE" = "1" ]; then
    OPTIONS="$OPTIONS --shuffle"
fi

# Run the nano-work-server with the constructed options
exec nano-work-server $OPTIONS