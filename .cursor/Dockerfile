# Cloud Agent base image for the "Empires of Olympus" Godot project.
#
# Godot 4.4 is required: the bundled VFX scripts use the `@export_tool_button`
# annotation, which only exists in 4.4+. The Linux binary only hard-links glibc;
# every windowing/GL library is loaded via dlopen at runtime, so we install
# exactly the shared libraries the engine opens for headless work and for
# software-GL (llvmpipe) rendering under Xvfb, plus git/curl/unzip.
FROM ubuntu:24.04

ARG GODOT_VERSION=4.4.1-stable
ARG GODOT_ZIP=Godot_v4.4.1-stable_linux.x86_64

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        git \
        xvfb \
        libgl1 \
        libglx-mesa0 \
        libgl1-mesa-dri \
        libx11-6 \
        libx11-xcb1 \
        libxcursor1 \
        libxinerama1 \
        libxrandr2 \
        libxi6 \
        libxext6 \
        libxfixes3 \
        libxrender1 \
        libxxf86vm1 \
        libxkbcommon0 \
        libfontconfig1 \
        libfreetype6 \
        libasound2t64 \
        libpulse0 \
        libudev1 \
    && rm -rf /var/lib/apt/lists/*

# Install the Godot 4.3 editor binary (headless-capable) as `godot`.
RUN curl -fsSL -o /tmp/godot.zip \
        "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_ZIP}.zip" \
    && unzip -o /tmp/godot.zip -d /tmp \
    && mv "/tmp/${GODOT_ZIP}" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm -f /tmp/godot.zip

# `ubuntu` (uid 1000) already exists in the base image; environment.json runs as it.
USER ubuntu

RUN godot --version
