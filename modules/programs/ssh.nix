_: {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  programs.ssh.extraConfig = ''
    Host builder
      HostName 192.168.1.XXX
      User nixbuilder
      IdentityFile /root/.ssh/nixbuilder
      IdentitiesOnly yes
  '';

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
}
