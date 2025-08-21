let
  secrets = import ../secrets.nix;
in
{
  network = {
    staticIP = secrets.staticIP;
    gateway = secrets.gateway;
    interface = secrets.interface;
    subnet = secrets.subnet;
  };
  
  # Service ports
  ports = {
    adguard = 3000;
    dns = 53;
    ssh = 22;
  };
  
  # Hostnames
  hostnames = {
    adguard = "adguard.home";
  };
}