{ pkgs, ... }:

{
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

  boot.initrd.systemd = {
    suppressedUnits = [
      "systemd-machine-id-commit.service"
    ];

    services.rollback-root = {
      description = "Recreate the ephemeral Btrfs root subvolume";
      requiredBy = [ "initrd.target" ];
      requires = [ "initrd-root-device.target" ];
      after = [
        "initrd-root-device.target"
        "local-fs-pre.target"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };
      script = ''
        mkdir -p /btrfs_tmp
        mount -o subvolid=5 /dev/disk/by-label/nixos /btrfs_tmp

        delete_subvolume_recursively() {
          IFS=$'\n'
          for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$subvolume"
          done
          btrfs subvolume delete "$1"
        }

        if [[ -e /btrfs_tmp/root ]]; then
          delete_subvolume_recursively /btrfs_tmp/root
        fi

        btrfs subvolume create /btrfs_tmp/root
        umount /btrfs_tmp
      '';
    };

    extraBin = {
      btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
      cut = "${pkgs.coreutils}/bin/cut";
      mkdir = "${pkgs.coreutils}/bin/mkdir";
    };
  };

  systemd.suppressedSystemUnits = [
    "systemd-machine-id-commit.service"
  ];
}
