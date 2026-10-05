{ ... }:

{
  boot.loader = {
    grub = {
      enable = true;
      device = "/dev/vda";
      configurationLimit = 2;
    };

    timeout = 5;
  };
}
