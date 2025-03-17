#!/bin/bash

# Exit on any error
set -e

# Configuration
CONTAINER_NAME="test-dev-container"
IMAGE_NAME="test-dev-image"

# Parse command line arguments
DAEMON_MODE=false
INTERACTIVE=true

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--daemon)
      DAEMON_MODE=true
      INTERACTIVE=false
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if the image exists
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "Error: Docker image '$IMAGE_NAME' not found."
    echo "Please run './build.sh' first to build the image."
    exit 1
fi

# Check if SSH agent is running
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "Warning: SSH agent doesn't appear to be running. Starting one for you..."
    eval $(ssh-agent)
    echo "Please add your SSH key to the agent:"
    echo "ssh-add ~/.ssh/your_key"
fi

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container is already running."
        if [ "$INTERACTIVE" = true ]; then
            echo "Attaching to it..."
            docker exec -it "$CONTAINER_NAME" bash
        else
            echo "Use 'docker exec -it $CONTAINER_NAME bash' to attach to it."
        fi
        exit 0
    else
        # Stop and remove the existing container
        echo "Removing existing container..."
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
fi

DOCKER_ARGS=""
if [ "$DAEMON_MODE" = true ]; then
    echo "Creating and starting container in daemon mode..."
    DOCKER_ARGS="-d"
else
    echo "Creating and starting container in interactive mode..."
    DOCKER_ARGS="-it"
fi

mkdir -p ~/.cache/remote_dev_jetbrains

# Run the container with SSH agent forwarding
docker run $DOCKER_ARGS \
    --name "$CONTAINER_NAME" \
    -v "$(pwd):/host" \
    -v /tmp:/tmp \
    -v $HOME/.cache/remote_dev_jetbrains:/root/.cache/JetBrains \
    -v "$SSH_AUTH_SOCK:/ssh-agent" \
    -e SSH_AUTH_SOCK=/ssh-agent \
    -p 0.0.0.0:2222:22 \
    "$IMAGE_NAME" $([[ "$DAEMON_MODE" = true ]] && echo "-d")

if [ "$DAEMON_MODE" = true ]; then
    echo "Container is running in background."
    echo "SSH server is available at 0.0.0.0:2222"
    echo "Username: root"
    echo "Password: root"
    echo ""
    echo "You can connect CLion via SSH to 0.0.0.0:2222"
    echo "You can attach to the container with: docker exec -it $CONTAINER_NAME bash"
fi
