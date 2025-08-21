{ config, lib, pkgs, ... }:

{
  # === BOOT CONFIGURATION ===
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
}
