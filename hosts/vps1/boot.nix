{ ... }:

{
  boot.loader = {
    grub = {
      enable = true;
      device = "/dev/vda";
      useOSProber = true;
    };

    timeout = 10;
  };
}
