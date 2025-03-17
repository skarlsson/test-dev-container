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
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Enable SSH agent forwarding and key authentication
RUN echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Install Bazel 6.5.0
RUN wget -O /tmp/bazel.sh https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-installer-linux-x86_64.sh && \
    chmod +x /tmp/bazel.sh && \
    /tmp/bazel.sh && \
    rm /tmp/bazel.sh

# Pre-install JetBrains backend
RUN mkdir -p /opt/jetbrains

# Create working directory
WORKDIR /workspace

# Create a script to start SSH server and setup workspace
RUN echo '#!/bin/bash\n\
\n\
# Setup SSH directory and authorized_keys from environment variable\n\
mkdir -p ~/.ssh\n\
chmod 700 ~/.ssh\n\
touch ~/.ssh/authorized_keys\n\
chmod 600 ~/.ssh/authorized_keys\n\
\n\
# If SSH_AUTHORIZED_KEYS environment variable is set, write it to authorized_keys file\n\
if [ ! -z "$SSH_AUTHORIZED_KEYS" ]; then\n\
  echo "$SSH_AUTHORIZED_KEYS" > ~/.ssh/authorized_keys\n\
  echo "Added authorized keys from environment variable"\n\
fi\n\
\n\
# Start SSH server in the background\n\
service ssh start\n\
echo "SSH server started. You can connect via SSH on port 2222"\n\
echo "Use: ssh -A -p 2222 root@localhost"\n\
\n\
# Generate known_hosts file if it does not exist\n\
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
# Print some diagnostics\n\
echo "Java home is: $JAVA_HOME"\n\
java -version\n\
\n\
exec "$@"' > /usr/local/bin/setup-workspace.sh && \
    chmod +x /usr/local/bin/setup-workspace.sh

# Setup entrypoint to use our script
ENTRYPOINT ["/usr/local/bin/setup-workspace.sh"]

# Default command
CMD ["/bin/bash"]

# Expose SSH port
EXPOSE 22
