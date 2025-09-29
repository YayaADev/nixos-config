# Complete Guide: Installing NixOS on CM3588 SBC

This guide will walk you through installing NixOS on a FriendlyELEC CM3588 (or CM3588 Plus) with eMMC storage.

## Prerequisites

**What You Need:**
- CM3588 SBC with eMMC storage
- MicroSD card (8GB minimum, Class 10 or better)
- Computer to prepare the SD card
- Network connection (Ethernet recommended)

**Files to Download:**
1. CM3588-compatible NixOS image from [nixos-aarch64-images](https://github.com/Mic92/nixos-aarch64-images)
   - Build command: `nix-build -A cm3588NAS`
   - Or download pre-built image if available

## Part 1: Prepare the SD Card Installer

### Step 1: Flash NixOS Image to SD Card

**On Linux:**
```bash
# Extract if compressed
gunzip your-nixos-cm3588-image.img.gz

# Flash to SD card (replace sdX with your SD card device)
sudo dd if=your-nixos-cm3588-image.img of=/dev/sdX bs=4M status=progress conv=fsync
```

**On Windows: (didnt test test method)** 
- Use [Balena Etcher](https://www.balena.io/etcher/) or [Rufus](https://rufus.ie/)
- Select the NixOS image file
- Select your SD card
- Click "Flash"

**On macOS:**
```bash
# Find SD card device
diskutil list

# Unmount (replace diskN with your SD card)
diskutil unmountDisk /dev/diskN

# Flash image
sudo dd if=your-nixos-cm3588-image.img of=/dev/rdiskN bs=4m
```

### Step 2: Add SSH Key to SD Card
This is required so you can ssh into it from a different computer on boot.

After flashing, mount the SD card on your computer:

```bash
# Create SSH directory structure
sudo mkdir -p /path/to/sdcard/home/nixos/.ssh

# Add your SSH public key
echo "your-ssh-public-key-here" | sudo tee /path/to/sdcard/home/nixos/.ssh/authorized_keys

# Set correct permissions
sudo chmod 700 /path/to/sdcard/home/nixos/.ssh
sudo chmod 600 /path/to/sdcard/home/nixos/.ssh/authorized_keys
```

The correct directory structure should be:
```
/home/nixos/.ssh/authorized_keys (mode: 600)
/home/nixos/.ssh/ (mode: 700, owner: nixos)
/home/nixos/ (mode: 755, owner: nixos)
```

### Step 3: Unmount and Insert SD Card

```bash
# Safely eject SD card
sudo umount /path/to/sdcard

# Insert SD card into CM3588
```

## Part 2: Boot and Access the Installer

### Step 4: First Boot from SD Card

1. Insert SD card into CM3588
2. Connect Ethernet cable
3. Power on the CM3588
4. Wait 1-2 minutes for boot

### Step 5: Find the IP Address

Check your router's DHCP client list for a device named "nixos" or similar, or scan your network:

```bash
# From your computer
nmap -sn 192.168.1.0/24
# Or use your router's admin interface
```

### Step 6: SSH into the System

```bash
ssh nixos@<ip-address>
# Example: ssh nixos@192.168.1.100
```

## Part 3: Install NixOS to eMMC

### Step 7: Identify Storage Devices

```bash
lsblk
```

You should see:
- `mmcblk0` - eMMC storage (target)
- `mmcblk1` - SD card (currently running)
- `nvme0n1`, `nvme1n1` - Any NVMe drives

### Step 8: Copy Bootloader from SD to eMMC

This is the critical step for CM3588 boot support:

```bash
# Copy the first 64MB (includes all RK3588 bootloader components)
sudo dd if=/dev/mmcblk1 of=/dev/mmcblk0 bs=1M count=64 conv=fsync status=progress
```

This takes 2-3 minutes and is essential for proper boot.

### Step 9: Create Partitions on eMMC

```bash
sudo fdisk /dev/mmcblk0
```

In fdisk, enter these commands:
```
g                    # Create new GPT partition table
n                    # New partition
1                    # Partition number 1
131072               # Start at 64MB (after bootloader area)
+512M                # 512MB for boot
t                    # Change partition type
1                    # Select EFI System type
n                    # New partition
2                    # Partition number 2
<Enter>              # Default start
<Enter>              # Use all remaining space
w                    # Write changes and exit
```

### Step 10: Format Partitions

```bash
# Format boot partition as FAT32
sudo mkfs.vfat -F32 /dev/mmcblk0p1

# Format root partition as ext4
sudo mkfs.ext4 /dev/mmcblk0p2
```

### Step 11: Mount Partitions

```bash
# Mount root partition
sudo mount /dev/mmcblk0p2 /mnt

# Create and mount boot partition
sudo mkdir /mnt/boot
sudo mount /dev/mmcblk0p1 /mnt/boot

# Verify mounts
df -h /mnt /mnt/boot
```

### Step 12: Generate NixOS Configuration

```bash
# Generate hardware configuration
sudo nixos-generate-config --root /mnt

# Create main configuration file
sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << 'EOF'
{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ARM bootloader configuration (required for CM3588)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Networking
  networking.hostName = "nixos-cm3588";
  networking.useDHCP = lib.mkDefault true;
  
  # Timezone (change to your timezone)
  time.timeZone = "America/Los_Angeles";

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # User account
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # Add your SSH public key here
    openssh.authorizedKeys.keys = [
      "your-ssh-public-key-here"
    ];
  };

  # Allow sudo without password
  security.sudo.wheelNeedsPassword = false;

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
  ];

  system.stateVersion = "25.05";
}
EOF
```

**Important:** Replace `"your-ssh-public-key-here"` with your actual SSH public key.

### Step 13: Install NixOS

```bash
# Run the installation (this takes 10-20 minutes)
sudo nixos-install

# The installer will download and install packages
# When prompted for root password, set one or skip
```

### Step 14: Clean Up and Prepare for First Boot

```bash
# Unmount filesystems
sudo umount /mnt/boot /mnt

# Shutdown the system
sudo shutdown -h now
```

## Part 4: First Boot from eMMC

### Step 15: Boot Without SD Card

1. **Remove the SD card**
2. Power on the CM3588
3. Wait 1-2 minutes for boot
4. Check your router for the device (IP may change)

### Step 16: Verify Boot Success

```bash
# SSH into the system
ssh nixos@<new-ip-address>

# Verify you're on eMMC
lsblk
# You should see mmcblk0p2 mounted at /
```

## Troubleshooting

### Issue: 2 Solid Red Lights (No Boot)

**Cause:** Bootloader not properly installed to eMMC

**Solution:** Boot back from SD card and repeat Step 8 (64MB bootloader copy), ensuring you copy the full 64MB.

### Issue: Can't SSH After Boot

**Possible causes:**
1. IP address changed - check router
2. SSH key not properly configured - use password authentication
3. Network not configured - connect monitor to check

### Issue: SD Card Won't Boot

**Solution:** 
- Verify image is CM3588-compatible
- Re-flash SD card
- Try different SD card (some cards are incompatible)

## Post-Installation

### Update System Configuration

```bash
# Edit configuration
sudo nano /etc/nixos/configuration.nix

# Rebuild system
sudo nixos-rebuild switch
```

### Optional: Add More Packages

Edit `/etc/nixos/configuration.nix` and add to `environment.systemPackages`:
```nix
environment.systemPackages = with pkgs; [
  vim
  wget
  curl
  git
  htop
  docker        # Add Docker
  mergerfs      # For NAS usage
  # Add more packages as needed
];
```

### Enable Additional Services

```nix
# Add to configuration.nix
virtualisation.docker.enable = true;  # Enable Docker
services.samba.enable = true;         # Enable Samba
```

## Key Points to Remember

1. **The 64MB bootloader copy is critical** - CM3588/RK3588 requires extensive bootloader components
2. **Partitions must start after 64MB** - Don't overlap with bootloader area
3. **Use extlinux bootloader** - GRUB won't work on this ARM board
4. **SSH keys in configuration.nix** - Easier than modifying SD card image
5. **Keep SD card as backup** - Until you confirm eMMC boots successfully

## Success Indicators

You've successfully installed NixOS when:
- System boots without SD card
- No red lights (normal LED behavior)
- Can SSH into the system
- `lsblk` shows root on `mmcblk0p2` (eMMC)
- System is accessible on network

Your CM3588 is now running NixOS from eMMC!