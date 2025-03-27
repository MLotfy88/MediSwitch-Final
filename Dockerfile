# Base image with Ubuntu
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Set environment variables
ENV ANDROID_HOME=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    JAVA_HOME=/opt/jdk \
    NDK_HOME=/opt/android-sdk/ndk/27.0.12077973 \
    PATH=${PATH}:/opt/flutter/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/jdk/bin:/opt/android-sdk/ndk/27.0.12077973

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    wget \
    cmake \
    ninja-build \
    clang \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    libsqlite3-dev \
    # Additional dependencies for SQLCipher
    libssl-dev \
    # Dependencies for Flutter web support
    chromium-browser \
    # Dependencies for Linux desktop support
    libblkid-dev \
    libudev-dev \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && mkdir -p ${ANDROID_HOME}/platforms \
    && mkdir -p ${ANDROID_HOME}/build-tools \
    && mkdir -p ${ANDROID_HOME}/ndk \
    && mkdir -p ${FLUTTER_HOME} \
    && mkdir -p ${JAVA_HOME}

# Download and install JDK 23.0.2
RUN curl -L https://download.oracle.com/java/23/latest/jdk-23_linux-x64_bin.tar.gz -o jdk.tar.gz \
    && tar -xzf jdk.tar.gz -C ${JAVA_HOME} --strip-components=1 \
    && rm jdk.tar.gz

# Download and install Android SDK Command Line Tools
RUN curl -L https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -o cmdline-tools.zip \
    && unzip cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm cmdline-tools.zip

# Accept Android SDK licenses
RUN yes | sdkmanager --licenses

# Install Android SDK components
RUN sdkmanager "platform-tools" \
    "platforms;android-28" \
    "platforms;android-29" \
    "platforms;android-33" \
    "platforms;android-34" \
    "platforms;android-35" \
    "build-tools;30.0.3" \
    "build-tools;34.0.0" \
    "build-tools;36.0.0" \
    "ndk;27.0.12077973"

# Download and install Flutter SDK 3.29.2
RUN curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.2-stable.tar.xz -o flutter.tar.xz \
    && tar -xf flutter.tar.xz -C /opt \
    && rm flutter.tar.xz

# Pre-download Flutter artifacts and accept licenses
RUN flutter doctor --android-licenses \
    && flutter precache \
    && flutter config --no-analytics \
    && flutter doctor

# Install Dart SDK 3.7.2 (specific version as mentioned in env.md)
RUN cd ${FLUTTER_HOME}/bin && \
    flutter version 3.29.2 && \
    flutter --version && \
    dart --version

# Install Flutter dependencies for the project
WORKDIR /app

# Copy pubspec files first to leverage Docker cache
COPY pubspec.yaml pubspec.lock* ./

# Get Flutter dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Set up SQLCipher for secure database
RUN flutter pub run sqflite_sqlcipher:setup

# Build configurations
# Development build
RUN echo "Building development APK..." && \
    flutter build apk --debug

# Production build
RUN echo "Building production APK..." && \
    flutter build apk --release --obfuscate --split-debug-info=./debug-info

# Expose port for web development server
EXPOSE 8080

# Create a volume for persistent storage
VOLUME ["/app/build"]

# Set up entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo 'case "$1" in' >> /entrypoint.sh && \
    echo '  run)' >> /entrypoint.sh && \
    echo '    flutter run --release' >> /entrypoint.sh && \
    echo '    ;;' >> /entrypoint.sh && \
    echo '  build)' >> /entrypoint.sh && \
    echo '    flutter build apk --release' >> /entrypoint.sh && \
    echo '    ;;' >> /entrypoint.sh && \
    echo '  test)' >> /entrypoint.sh && \
    echo '    flutter test' >> /entrypoint.sh && \
    echo '    ;;' >> /entrypoint.sh && \
    echo '  web)' >> /entrypoint.sh && \
    echo '    flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0' >> /entrypoint.sh && \
    echo '    ;;' >> /entrypoint.sh && \
    echo '  *)' >> /entrypoint.sh && \
    echo '    exec "$@"' >> /entrypoint.sh && \
    echo '    ;;' >> /entrypoint.sh && \
    echo 'esac' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]