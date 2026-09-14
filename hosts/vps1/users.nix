{ ... }:

{
  users.users.server = {
    isNormalUser = true;
    description = "server";
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;
}
