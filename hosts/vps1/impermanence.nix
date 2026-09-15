{ ... }:

{
  imports = [
    ./rollback-root.nix
  ];

  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/3x-ui"
      "/var/lib/containers"
      "/var/lib/nixos"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  boot.initrd.systemd.suppressedUnits = [
    "systemd-machine-id-commit.service"
  ];
  systemd.suppressedSystemUnits = [
    "systemd-machine-id-commit.service"
  ];
}
