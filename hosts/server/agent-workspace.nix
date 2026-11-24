{ pkgs, ... }:

let
  pi = pkgs.writeShellScriptBin "pi" ''
    exec ${pkgs.nodejs_24}/bin/npx --yes @earendil-works/pi-coding-agent "$@"
  '';

  piOrchestrator = pkgs.writeShellScriptBin "pi-orchestrator" ''
    exec ${pi}/bin/pi -e npm:@groeponline/pi-agent-orchestrator "$@"
  '';
in
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
      nodejs_24
      pi
      piOrchestrator
    ];
  };
}
