{pkgs, ...}: {
  # --- Boot Loader ---
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # --- Firmware ---
  hardware.firmware = [pkgs.linux-firmware];
  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
  };

  # Kernel modules for RK3588 hardware acceleration & NPU support
  # Used for immich & jellyfin
  boot.kernelModules = [
    "rknpu"
    "rockchip_rga"
    "rockchip_vdec"
  ];
}
