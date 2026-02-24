#!/bin/bash
# Install Flutter from the stable channel
echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Precache flutter web dependencies
flutter config --enable-web
flutter precache

# Build the web application
echo "Building Flutter Web..."
flutter pub get
flutter build web --release
