_: {
  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", GROUP="video", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="rga", GROUP="video", MODE="0664"
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
    SUBSYSTEM=="drm", KERNEL=="card*", GROUP="video", MODE="0664"
    SUBSYSTEM=="mpp_class", KERNEL=="mpp_service", GROUP="video", MODE="0664"
    SUBSYSTEM=="dma_heap", KERNEL=="*", GROUP="video", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="rknpu", GROUP="video", MODE="0664"
  '';
}
