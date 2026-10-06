# VPS2 NixOS ISO network bootstrap

These commands restore temporary network and administrative access after each
boot of the NixOS installer ISO. They affect only the live ISO environment and
do not persist after a reboot.

Run them from the provider console.

## Become root

```bash
sudo -i
```

## Detect and configure the network interface

The installed Ubuntu used `eth0`, but the NixOS ISO may assign another name,
such as `ens3`. Detect the first non-loopback interface instead of assuming its
name:

```bash
ip -br link

VPS_IFACE="$(ip -o link show | awk -F': ' '$2 != "lo" {sub(/@.*/, "", $2); print $2; exit}')"
printf 'Interface: %s\n' "$VPS_IFACE"

ip link set "$VPS_IFACE" up
ip address replace 104.128.142.208/24 dev "$VPS_IFACE"
ip route replace default via 104.128.142.1 dev "$VPS_IFACE"
```

## Configure DNS

The ISO does not provide `systemd-resolved`, so `resolvectl` does not work.
Install a regular resolver file:

```bash
printf '%s\n' \
  'nameserver 8.8.8.8' \
  'nameserver 1.1.1.1' \
  | install -m 644 /dev/stdin /etc/resolv.conf
```

If the command reports a problem with an existing symlink, replace that link
and create the file directly:

```bash
rm -f /etc/resolv.conf

printf '%s\n' \
  'nameserver 8.8.8.8' \
  'nameserver 1.1.1.1' \
  > /etc/resolv.conf
```

## Verify internet access

```bash
ip -br address show "$VPS_IFACE"
ip route
cat /etc/resolv.conf

ping -c 3 104.128.142.1
ping -c 3 1.1.1.1
getent hosts cache.nixos.org
```

Do not continue until the gateway, public IPv4 connectivity, and DNS lookup all
work.

## Install the administrative public key

Install the key for both `root` and the ISO's regular `nixos` user:

```bash
install -d -m 700 /root/.ssh

printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbguy5Xd0uBsN7azv2O4AmjWHUebZz8EbVVwm3Me8n egor@Egors-laptop' \
  | install -m 600 /dev/stdin /root/.ssh/authorized_keys

install -d -o nixos -g users -m 700 /home/nixos/.ssh

printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbguy5Xd0uBsN7azv2O4AmjWHUebZz8EbVVwm3Me8n egor@Egors-laptop' \
  | install -o nixos -g users -m 600 /dev/stdin /home/nixos/.ssh/authorized_keys
```

## Start remote access

```bash
systemctl start sshd.service
systemctl status sshd.service --no-pager
ss -lntp | grep ':22'
```

Connect as `root` first. If the ISO rejects root login, connect as `nixos` and
run `sudo -i`:

```bash
ssh root@104.128.142.208
ssh nixos@104.128.142.208
```
