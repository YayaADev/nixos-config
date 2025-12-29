
### **NixOS eMMC Recovery Guide** 

This guide assumes you have booted from a working NixOS installer on an SD card and your broken installation is on the eMMC storage (`/dev/mmcblk0`).

---

### Step 1: Mount the eMMC Filesystems

First, you need to make the broken system's files accessible.
    
2. Identify your eMMC partitions. You can confirm them with `lsblk`. It's usually `/dev/mmcblk0p2` for the root (`/`) partition and `/dev/mmcblk0p1` for the boot (`/boot`) partition.
    
3. Mount the partitions to the `/mnt` directory on the live system:
    
    Bash
    
    ```
    # Mount the main root partition
    sudo mount /dev/mmcblk0p2 /mnt
    
    # Mount the boot partition inside the root mount
    sudo mount /dev/mmcblk0p1 /mnt/boot
    ```
    

---

### Step 2: Enter the eMMC System (Chroot)

Now, you need to "enter" the broken system to run repair commands as if you were booted into it. 

```
sudo nixos-enter --root /mnt
```

If this command succeeds, your terminal prompt will change, and you will be operating as the `root` user _inside your eMMC installation_.

---

###  Step 3: Navigate and Fix Your Configuration

With your terminal now inside the broken system, go to your configuration files and fix the error.
    
    
    cd /path/to/nixosconfig && nano configuration.nix
    
    
1. Find and correct the mistake. Save and exit the editor.
    

---

### Step 4: Rebuild the System

 From inside the chroot, you need to rebuild your configuration. Use the `boot` command, as `switch` will fail in this environment.

Bash

```
nixos-rebuild boot
```

**Why `boot` instead of `switch`?** The `nixos-rebuild switch` command tries to activate the new configuration by communicating with the `systemd` process. In a chroot environment, your eMMC's `systemd` isn't running, causing errors. The `nixos-rebuild boot` command simply builds the new configuration and updates the bootloader to make it the default, which is exactly what you need.

---

### Step 5: Exit, Unmount, and Reboot

Once the rebuild completes successfully, the repair is done.

1. Leave the chroot environment:
    
    ```
    exit
    ```
    
1. Unmount the eMMC partitions from the live system:
    
    ```
    sudo umount -R /mnt
    ```
    
1. Reboot the device. **Remember to remove the SD card** so it boots from the eMMC.
    
    ```
    sudo reboot
    ```