# agents.nix

Nix packages for coding agent harnesses, from upstream binaries. Targets `x86_64-linux` and `aarch64-linux`.

## Usage

```sh
nix run github:asp345/agents.nix#pi
```

In a flake, add the overlay:

```nix
{
  inputs.agents.url = "github:asp345/agents.nix";

  outputs = { nixpkgs, agents, ... }: {
    nixpkgs.overlays = [ agents.overlays.default ];
  };
}
```

Some packages are unfree; add them to `allowUnfreePredicate` when using the overlay.

## Home Manager

```nix
{
  imports = [ inputs.agents.homeManagerModules.magpie ];

  services.magpie = {
    enable = true;
    webKey = "…";
  };
}
```

## Updates

Every package ships `update.sh`, which reads the upstream version and prefetches new hashes into `sources.json`. GitHub Actions runs them on a schedule, builds what changed on both systems, and commits. `flake.lock` is updated daily.
