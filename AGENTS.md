# NixOS repository instructions

## 1. Working environments

- The production host runs NixOS.
- The agent team runs Codex CLI as the unprivileged `agent` user on the server. It uses its own repository clone and task-specific Git worktrees; do not assume that the administrator's checkout or home directory is accessible.
- The owner may also work with a separate checkout on Windows. Treat each checkout independently and inspect its current Git state before working.
- Use the repository and worktree explicitly assigned to the task. Do not guess paths or assume that two checkouts are synchronized.
- Windows WSL has separate `Ubuntu` and `NixOS` distributions. Currently only `Ubuntu` works. Use `wsl.exe -d Ubuntu` for local WSL checks; do not attempt to use the non-working `NixOS` distribution.
- `hosts/wsl` and its corresponding flake output are abandoned legacy targets. Do not inspect, evaluate, build, edit, or maintain them unless the owner explicitly requests WSL host work. This does not prohibit using the working Ubuntu WSL distribution for repository checks.

## 2. Normal development autonomy

Within the scope of an assigned task, agents may work independently in their assigned repository clone and worktree:

- inspect files, history, and repository structure;
- create task branches and Git worktrees;
- edit, add, stage, and locally commit task-related files;
- run relevant local tests, formatters, linters, Nix evaluation, builds, and checks;
- make and verify corrections that remain within the approved task scope;
- prepare a change for review and, when explicitly delegated, integrate it into the local target branch as described in the team workflow.

Repository rules are the mandatory safety boundary. Shared workflow, role
instructions, and task records may only narrow these rules, except for an
explicit task-level delegation that remains within them. A permissive sentence
never overrides this file.

For each task and reviewed range, Developer, Reviewer, and Integrator must be
three distinct people/agents. Self-review and self-integration are forbidden;
no waiver is available. Developer may make ordinary local commits in approved
scope and the assigned task branch/worktree, but push and merge remain separate
authority gates. Reviewer is inspection-only. Only Integrator may write a
shared target checkout after the task authority gate.

Do not ask the owner to approve every ordinary file edit, local commit, or non-activating check. The task assignment is the authority for routine work within its stated scope.

Always inspect the current branch, `git status`, and existing diff before editing. Preserve all pre-existing changes. Never discard, overwrite, stage, commit, amend, or include unrelated work. If the assigned worktree contains changes that are not clearly part of the task, stop and clarify.

## 3. Approval-required operations

Obtain explicit owner approval before performing any of the following, even when a task generally authorizes implementation:

- **NixOS activation or rollback:** `nixos-rebuild switch`, `boot`, `test`, `rollback`, equivalent activation commands, reboot, or shutdown.
- **Live networking and remote access:** changes to firewall rules, DNS, routes, NetworkManager profiles, Xray/VPN, AmneziaWG, reverse SSH tunnels, SSH daemon settings, or starting, stopping, or restarting their services.
- **Remote host operations:** running commands on another host, opening an SSH session to another host for operational work, or transferring files to or from a remote host.
- **Storage and persistence:** changes to EFI/NVRAM, bootloaders, partitions, filesystems, mounts, UUIDs, `/persist`, `/nix`, `/media`, swap, formatting, or deletion/movement of user data.
- **Destructive Nix store operations:** `nix-collect-garbage`, `nix store delete`, `nix-store --delete`, profile deletion, or equivalent cleanup that removes stored data.
- **Secrets and key material:** decrypting or displaying SOPS data; reading, exporting, moving, or changing age/private keys; editing encrypted secret values; handling credentials. `secrets.yaml` is encrypted SOPS data and must never be decrypted merely for inspection.
- **Dependency pin changes:** `nix flake update`, editing `flake.lock`, or otherwise changing pinned dependency revisions.
- **External publication:** `git push`, creating or updating a pull request, publishing releases, or making external service/API changes.

The requirement is based on the operation and its effects, not on whether a command happens to contain a particular word. Ordinary local inspection of configuration text is not prohibited merely because it mentions `ssh`, `sops`, or `age`.

Never expose decrypted secrets, private keys, passwords, tokens, or credential contents in terminal output, patches, commits, logs, or replies. Never add plaintext credentials or real secret values to tracked files.

## 4. Local Git integration

The normal team workflow is local. GitHub pull requests and remote pushes are not part of ordinary task completion.

- Developer works and commits in a task-specific branch/worktree.
- Reviewer independently reviews the exact commit(s) proposed for integration.
- Only the Integrator performs a merge into the designated local target branch, and only when the task explicitly delegates integration/merge.
- The Integrator must use the existing local target checkout, verify its state, and follow `agents/integrator.md`.
- Do not merge directly from Developer or Reviewer roles.
- Do not push as part of local integration. A push requires a separate explicit instruction and approval.
- Do not delete task branches or worktrees automatically after merge. Cleanup must be within the delegated task scope or separately approved.

A successful local merge does not authorize NixOS activation, service restarts, or deployment.

## 5. NixOS checks and operational safeguards

- Treat `nix build`, `nix flake check`, and evaluation as non-activation checks. They may download dependencies and populate the Nix store. Mention material download/build costs before starting when relevant.
- For configuration changes, prefer evaluation and non-activating checks before proposing activation.
- Summarize relevant system effects and operational risks before requesting activation approval.
- Treat full-tunnel VPN routing and its watchdog (Xray or AmneziaWG) as connectivity-critical. Do not restart or modify them without explicit approval.
- Treat media paths as user data. Do not delete, move, recursively chmod, or reconfigure download locations without explicit approval.
- Do not assume that a successful evaluation or build proves runtime behavior.
- If a check requires an unavailable private flake input or secret, report the limitation. Do not attempt to obtain or bypass access to it.

## 6. Review and reporting

- Changes involving access, networking, storage, boot, persistence, or secrets must explicitly describe operational risk in the implementation report and review.
- Distinguish confirmed facts, deductions, assumptions, and unknowns.
- Report checks actually performed and their exact outcomes. Do not claim that an unrun check passed.
- If repository instructions conflict with a task request, or the task requires an approval-required operation, stop and ask the owner.

If a merge conflict occurs, abort with `git merge --abort` before changing the
target unless the task record already contains owner permission naming source
HEAD, target HEAD, conflict scope, and resolution boundaries. An authorized
resolution must occur in a temporary integration branch/worktree and receive a
fresh independent review of the exact result before target merge. Target
movement or a changed conflict requires new permission and review.
