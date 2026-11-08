# agents.nix

Nix packages for coding agent harnesses, built from upstream releases for Linux.

```sh
nix run github:asp345/agents.nix#pi
```

Overlay:

```nix
nixpkgs.overlays = [ inputs.agents.overlays.default ];
```

`claude-code` and `rtk` are unfree.

Home Manager:

```nix
{
  imports = [ inputs.agents.homeManagerModules.magpie ];
  services.magpie = {
    enable = true;
    webKey = "…";
  };
}
```

`packages/*/update.sh` updates `packages/*/sources.json`. GitHub Actions runs them on a schedule, builds the packages, and commits.
