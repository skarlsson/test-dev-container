# Connecting CLion to Docker Container via SSH

This guide explains how to connect CLion directly to your Docker development container using SSH.

## Prerequisites

- Docker container running with SSH server (port 2222)
- CLion installed on your local machine

## Step 1: Start the Container in Daemon Mode

```bash
# Build the container if you haven't already
./build.sh

# Start the container in daemon mode
./run.sh --daemon
```

This will:
- Start the container in the background
- Start the SSH server inside the container
- Map port 2222 on your host to port 22 in the container
- Clone the repository inside the container

## Step 2: Configure CLion SSH Connection

1. Open CLion
2. Go to **File > Settings > Build, Execution, Deployment > Toolchains**
3. Click the **+** button to add a new toolchain
4. Select **Remote Host**
5. Configure the connection:
   - **Name**: Docker Container (or any name you prefer)
   - **Credentials**: Click **New**
     - **Host**: localhost
     - **Port**: 2222
     - **Username**: root
     - **Password**: root
     - **Authentication type**: Password
     - Click **Test Connection** to verify it works
     - Click **OK**
6. Wait for CLion to detect tools in the remote environment
7. Make sure CMake, GDB, Compiler, etc. are detected

## Step 3: Configure Bazel Integration

1. Go to **File > Settings > Build, Execution, Deployment > Bazel Settings**
2. Enable the Bazel plugin if it's not already enabled
3. Configure Bazel:
   - **Bazel binary location**: /usr/local/bin/bazel
   - **Bazel sync on project open**: Enabled
   - **Use project view file**: Disabled (or configure if needed)

## Step 4: Open the Project

1. Go to **File > Open**
2. In the dialog that appears, select **Open from Remote Host**
3. Select the SSH connection you created
4. Navigate to `/workspace/test-dev-bazel`
5. Click **OK**

CLion will sync the project files and configure Bazel. Once it's done, you should be able to build and run the project directly from CLion.

## Troubleshooting

### SSH Connection Issues

If you have trouble connecting via SSH:

1. Verify the container is running:
   ```bash
   docker ps | grep test-dev-container
   ```

2. Check if SSH server is running inside the container:
   ```bash
   docker exec test-dev-container service ssh status
   ```

3. Test SSH connection from terminal:
   ```bash
   ssh -p 2222 root@localhost
   ```

### Bazel Detection Issues

If CLion doesn't properly detect Bazel:

1. Make sure the Bazel binary exists in the container:
   ```bash
   docker exec test-dev-container which bazel
   ```

2. Verify Bazel works in the container:
   ```bash
   docker exec test-dev-container bazel version
   ```

3. Manually set the Bazel binary path in CLion settings to `/usr/local/bin/bazel`
