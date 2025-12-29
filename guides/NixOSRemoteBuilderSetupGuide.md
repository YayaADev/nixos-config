# NixOS Remote Builder Setup Guide

Tested with my x86_64 Linux PC running Pos_OS COSMIC.

Setting up an x86_64  as a remote builder for an aarch64 NixOS SBC (Single Board Computer) using QEMU emulation. Goal was to build a kernel for the NPU on my SBC but i kept running out of emmc storage (used over 23GB for the build). 

## Overview

- **Local Machine (Client)**: NixOS on aarch64 SBC (e.g., CM3588 with NPU)
- **Remote Builder**: Pop!_OS (Ubuntu-based) on x86_64 with AMD Ryzen 9 5900X
---

## Part 1: Set Up Pop!_OS PC (The Builder)

### Step 1.1: Install Nix on Pop!_OS

```bash
# Install Nix (multi-user installation)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Restart your shell or source the profile
. /etc/profile.d/nix.sh
```

### Step 1.2: Enable QEMU/binfmt for aarch64 Emulation

```bash
sudo apt update
sudo apt install qemu-user-static binfmt-support
```

Verify it's working:

```bash
cat /proc/sys/fs/binfmt_misc/qemu-aarch64
```

You should see output containing `enabled` and `interpreter /usr/bin/qemu-aarch64-static`.

### Step 1.3: Create a Dedicated Builder User

```bash
sudo useradd -m nixbuilder
sudo passwd -l nixbuilder  # Lock password (SSH key only)
sudo mkdir -p /home/nixbuilder/.ssh
sudo chmod 700 /home/nixbuilder/.ssh
```

### Step 1.4: Configure Nix to Trust the Builder User and Support aarch64

```bash
# Add the builder user to trusted-users AND enable aarch64 platform
echo "trusted-users = root nixbuilder" | sudo tee -a /etc/nix/nix.conf
echo "extra-platforms = aarch64-linux" | sudo tee -a /etc/nix/nix.conf

# Restart the nix daemon
sudo systemctl restart nix-daemon
```

> **Important**: The `extra-platforms = aarch64-linux` line is critical! Without it, Nix won't know it can build aarch64 packages via QEMU.

### Step 1.4 Tell the Nix daemon that it supports aarch64-linux.

```bash
echo "extra-platforms = aarch64-linux" | sudo tee -a /etc/nix/nix.conf

# restat to apply
sudo systemctl restart nix-daemon

# Verify it works
/usr/bin/qemu-aarch64-static --version
```

### Step 1.5: Install and Configure SSH Server

If you dont have SSH server running:

```bash
# Install OpenSSH server
sudo apt install openssh-server

# Start and enable it
sudo systemctl enable --now ssh

# Verify it's running
sudo systemctl status ssh
```

Add Nix binaries to SSH PATH:

```bash
echo 'SetEnv PATH=/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' | sudo tee -a /etc/ssh/sshd_config

sudo systemctl restart ssh
```

---

## Part 2: Set Up NixOS SBC (The Client)

### Step 2.1: Generate SSH Key for Root

```bash
sudo -i
ssh-keygen -t ed25519 -f /root/.ssh/nixbuilder -N ""
```

### Step 2.2: Copy Public Key to Builder

Display the public key on your SBC:

```bash
cat /root/.ssh/nixbuilder.pub
```

Then on your x86 PC, add it to the builder user:

```bash
echo "YOUR_PUBLIC_KEY_HERE" | sudo tee /home/nixbuilder/.ssh/authorized_keys
sudo chown -R nixbuilder:nixbuilder /home/nixbuilder/.ssh
sudo chmod 600 /home/nixbuilder/.ssh/authorized_keys
sudo chmod 755 /home/nixbuilder
```

### Step 2.3: Configure SSH on NixOS SBC

Create the SSH config file (replace `192.168.1.XXX` with your x86 PC's IP):

```bash
sudo mkdir -p /root/.ssh

sudo tee /root/.ssh/config << 'EOF'
Host builder
  HostName 192.168.1.XXX
  User nixbuilder
  IdentityFile /root/.ssh/nixbuilder
  IdentitiesOnly yes
EOF

sudo chmod 600 /root/.ssh/config
```

### Step 2.4: Test SSH Connection

```bash
sudo ssh builder "nix-store --version"
```

This should return the Nix version without prompting for a password.

### Step 2.5: Configure NixOS to Use the Remote Builder

Add to your `configuration.nix` or flake configuration:

```nix
nix = {
  distributedBuilds = true;
  
  extraOptions = ''
    builders-use-substitutes = true
  '';
  
  buildMachines = [
    {
      hostName = "builder";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ]; 
      sshUser = "nixbuilder";
      sshKey = "/root/.ssh/nixbuilder";
      maxJobs = 10;      # Adjust based on CPU cores (Ryzen 9 5900X = 12 cores/24 threads)
      speedFactor = 10;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    }
  ];
};
```

Apply the configuration (this initial rebuild will still be local):

```bash
sudo nixos-rebuild switch --flake /path/to/config --impure
```

---

## Part 3: Building with Remote Builder

### Force All Builds to Remote (Recommended for Large Builds)

```bash
sudo nixos-rebuild test --flake /home/nixos/nixos-config --impure --max-jobs 0
```

The `--max-jobs 0` ensures nothing builds locally on the SBC — everything goes to the x86 PC.

For the actual switch:

```bash
sudo nixos-rebuild switch --flake /home/nixos/nixos-config --impure --max-jobs 0
```

---

## Quick Reference Commands

```bash
# Test connection (on SBC)
sudo ssh builder "nix-store --version"

# Build with remote builder (on SBC)
sudo nixos-rebuild switch --flake /home/nixos/nixos-config --impure --max-jobs 0

# Restart Nix daemon (on builder)
sudo systemctl restart nix-daemon

# Restart SSH (on builder)
sudo systemctl restart ssh

# Check QEMU registration (on builder)
cat /proc/sys/fs/binfmt_misc/qemu-aarch64
```
