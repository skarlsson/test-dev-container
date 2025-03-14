FROM ubuntu:22.04

# Set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools, SSH server, and OpenJDK
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    unzip \
    zip \
    build-essential \
    pkg-config \
    python3 \
    python3-pip \
    cmake \
    ninja-build \
    clang \
    openssh-client \
    openssh-server \
    lsb-release \
    sudo \
    gdb \
    rsync \
    openjdk-11-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure environment variables for Java
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Configure SSH server
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Install Bazel 6.5.0
RUN wget -O /tmp/bazel.sh https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-installer-linux-x86_64.sh && \
    chmod +x /tmp/bazel.sh && \
    /tmp/bazel.sh && \
    rm /tmp/bazel.sh

# Pre-install JetBrains backend
RUN mkdir -p /opt/jetbrains
WORKDIR /opt/jetbrains

# Install CLion EAP remote backend
#RUN wget -q https://download.jetbrains.com/cpp/CLion-241.11761.24.tar.gz && \
#    tar xzf CLion-241.11761.24.tar.gz && \
#    rm CLion-241.11761.24.tar.gz && \
#    mv clion-* clion && \
#    mkdir -p /root/.config/JetBrains/CLion2025.1 && \
#    mkdir -p /root/.cache/JetBrains/CLion2025.1

# Add the CLion bin directory to PATH
ENV PATH=$PATH:/opt/jetbrains/clion/bin

# Install Bazel plugin for CLion EAP
#RUN mkdir -p /root/.config/JetBrains/CLion2025.1/plugins && \
#    cd /root/.config/JetBrains/CLion2025.1/plugins && \
#    wget -q https://plugins.jetbrains.com/files/9554/428187/bazel-241.11761.14.zip && \
#    unzip bazel-241.11761.14.zip && \
#    rm bazel-241.11761.14.zip

# Create working directory
WORKDIR /workspace

# Create a script to clone the repository and start SSH server
RUN echo '#!/bin/bash\n\
\n\
# Start SSH server in the background\n\
service ssh start\n\
echo "SSH server started. You can connect via SSH on port 2222"\n\
\n\
# Check if SSH agent socket is available\n\
if [ -S "$SSH_AUTH_SOCK" ]; then\n\
  echo "SSH agent detected at $SSH_AUTH_SOCK"\n\
  \n\
  # Generate known_hosts file if it does not exist\n\
  mkdir -p ~/.ssh\n\
  if [ ! -f "$HOME/.ssh/known_hosts" ]; then\n\
    echo "Adding GitHub to known hosts..."\n\
    ssh-keyscan github.com > ~/.ssh/known_hosts 2>/dev/null\n\
    chmod 644 ~/.ssh/known_hosts\n\
  fi\n\
  \n\
  # Verify SSH connection\n\
  echo "Verifying SSH connection to GitHub..."\n\
  if ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then\n\
    echo "SSH authentication to GitHub successful"\n\
    \n\
    # Try to clone or update repository\n\
    if [ ! -d "/workspace/test-dev-bazel" ]; then\n\
      echo "Cloning repository..."\n\
      git clone git@github.com:skarlsson/test-dev-bazel.git /workspace/test-dev-bazel || {\n\
        echo "Failed to clone the repository. Please check your SSH setup."\n\
      }\n\
    else\n\
      echo "Updating repository..."\n\
      cd /workspace/test-dev-bazel && git pull || echo "Failed to pull updates."\n\
    fi\n\
  else\n\
    echo "SSH authentication to GitHub failed. Make sure your key is added to the SSH agent."\n\
    echo "You can add your key on the host with: ssh-add ~/.ssh/your_key"\n\
  fi\n\
else\n\
  echo "No SSH agent socket found at $SSH_AUTH_SOCK"\n\
  echo "Please make sure you forwarded your SSH agent to the container."\n\
fi\n\
\n\
# Print some diagnostics\n\
echo "Java home is: $JAVA_HOME"\n\
java -version\n\
echo "CLion EAP backend installed at: /opt/jetbrains/clion"\n\
echo "Bazel plugin installed at: /root/.config/JetBrains/CLion2025.1/plugins/bazel"\n\
\n\
exec "$@"' > /usr/local/bin/setup-workspace.sh && \
    chmod +x /usr/local/bin/setup-workspace.sh

# Setup entrypoint to use our script
ENTRYPOINT ["/usr/local/bin/setup-workspace.sh"]

# Default command
CMD ["/bin/bash"]

# Expose SSH port
EXPOSE 22
