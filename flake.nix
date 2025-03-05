# Pin hugo versions
# https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs
# NOTE: the hash now is locked in the flake.lock file
#       Using a flake makes pinning easier and the experience faster
#       thanks to caching

{
  description = "Blog dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/21808d22b1cda1898b71cf1a1beb524a97add2c4";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            hugo # v0.141.0+extended
            dart-sass # v1.83.1
          ];
        };
      });
}
