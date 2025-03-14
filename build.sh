#!/bin/bash

# Exit on any error
set -e

# Configuration
IMAGE_NAME="test-dev-image"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "Build completed successfully!"
echo "You can now run the container with './run.sh'"
