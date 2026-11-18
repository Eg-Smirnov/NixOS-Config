{ pkgs, ... }:

{
  users.groups.agent = { };

  users.users.agent = {
    isNormalUser = true;
    description = "Codex agent";
    group = "agent";
    home = "/persist/home/agent";
    homeMode = "0700";
    createHome = true;
    extraGroups = [ ];

    packages = with pkgs; [
      codex
      tmux
    ];
  };
}
