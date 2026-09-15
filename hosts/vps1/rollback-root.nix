{ pkgs, ... }:

{
  boot.initrd.systemd = {
    services.rollback-root = {
      description = "Rollback ephemeral Btrfs root subvolume";
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
        mount /dev/root_vg/root /btrfs_tmp

        if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
          IFS=$'\n'
          for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$subvolume"
          done
          btrfs subvolume delete "$1"
        }

        for old_root in $(find /btrfs_tmp/old_roots/ -mindepth 1 -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$old_root"
        done

        btrfs subvolume create /btrfs_tmp/root
        umount /btrfs_tmp
      '';
    };

    extraBin = {
      btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
      cut = "${pkgs.coreutils}/bin/cut";
      date = "${pkgs.coreutils}/bin/date";
      find = "${pkgs.findutils}/bin/find";
      mkdir = "${pkgs.coreutils}/bin/mkdir";
      mv = "${pkgs.coreutils}/bin/mv";
      stat = "${pkgs.coreutils}/bin/stat";
    };
  };
}
