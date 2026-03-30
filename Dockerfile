# --- Stage 1: Build ---
FROM rust:bookworm AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libglib2.0-dev \
    pkg-config \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install cargo-c
RUN cargo install cargo-c

# Clone the repository
WORKDIR /usr/src/gst-plugins-rs
RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git .

# Build a specific plugin (e.g., gst-plugin-tutorial) or all of them
# Note: Building ALL plugins can take a very long time and may require more deps.
# We'll use the 'fallbackswitch' plugin as a common example.
WORKDIR /usr/src/gst-plugins-rs/utils/fallbackswitch
RUN cargo cinstall --destdir=/target

# --- Stage 2: Runtime ---
FROM debian:bookworm-slim

# Enable non-free and non-free-firmware repos for Intel drivers
RUN sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources || \
    sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list

# Install runtime GStreamer libraries
RUN apt-get update && apt-get install -y \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-vaapi \
    libva-drm2 \
    libva-x11-2 \
    mesa-va-drivers \
    intel-media-va-driver-non-free \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled plugins from the builder
# GStreamer looks in /usr/lib/x86_64-linux-gnu/gstreamer-1.0 by default on Debian
# Use a wildcard to account for architecture-specific subdirectories
COPY --from=builder /target/usr/local/lib/*/gstreamer-1.0/ /usr/lib/x86_64-linux-gnu/gstreamer-1.0/

# Ensure GStreamer looks in /usr/lib/x86_64-linux-gnu/gstreamer-1.0
ENV GST_PLUGIN_PATH=/usr/lib/x86_64-linux-gnu/gstreamer-1.0

# Default environment variables (can be overridden at runtime)
ENV INPUT_URL="rtmp://your-source-url/live/stream"
ENV OUTPUT_URL="rtmp://your-destination-url/live/output"

STOPSIGNAL SIGINT

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]