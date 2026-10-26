{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.services.magpie;
  magpie = pkgs.callPackage ../packages/magpie/package.nix { };
in
{
  options.services.magpie = {
    enable = lib.mkEnableOption "magpie";
    webKey = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ magpie ];

    systemd.user.services.magpie = {
      Unit.Description = "magpie gateway";
      Service = {
        ExecStart = "${lib.getExe magpie} serve --web";
        Environment = [ "MAGPIE_WEB_KEY=${cfg.webKey}" ];
        Restart = "on-failure";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
