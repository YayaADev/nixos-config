{pkgs, ...}: {
  services.netdata = {
    enable = true;
    package = pkgs.netdata.override {withCloudUi = true;};
    config = {
      global = {
        "memory mode" = "dbengine";
        "page cache size" = 32;
        "dbengine multihost disk space" = 256;
      };
    };
  };
}
