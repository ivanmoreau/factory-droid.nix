{
  description = "Factory Droid CLI - AI software engineering agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Map Nix system to Factory's platform naming
        platformInfo = {
          "x86_64-linux" = { platform = "linux"; arch = "x64"; };
          "aarch64-linux" = { platform = "linux"; arch = "arm64"; };
          "x86_64-darwin" = { platform = "darwin"; arch = "x64"; };
          "aarch64-darwin" = { platform = "darwin"; arch = "arm64"; };
        }.${system};

        # Always use baseline variant for x86_64 (Nix derivations must be reproducible)
        archSuffix = 
          if pkgs.stdenv.hostPlatform.isx86_64
          then "-baseline"
          else "";
        
        droidArch = "${platformInfo.arch}${archSuffix}";
        
        version = "0.22.13";
        baseUrl = "https://downloads.factory.ai/factory-cli/releases/${version}";
        binaryUrl = "${baseUrl}/${platformInfo.platform}/${droidArch}/droid";

        # SHA256 hashes for each platform/arch combination
        hashes = {
          "linux-x64-baseline" = "sha256-ljCBFhWfHv7w1KZdK35LbMz66hAjDf3siRKxEij2htY=";
          "linux-arm64" = "sha256-oAu2VJ0akoHipVnB92mT5SNVWlTjR8hf0ag+1KNrDss=";
          "darwin-x64-baseline" = "sha256-ElcTeg+yGWAaPsYF6UHECV+0vEtQ5QDfzbuqi3Lpq38=";
          "darwin-arm64" = "sha256-pyNvGA771immArkQcQsaPwT28HZYKC9iHRFpzJ+pcQA=";
        };
        
        hashKey = "${platformInfo.platform}-${droidArch}";

      in rec {
        packages = {
          factory-droid = let
            droidBinary = pkgs.fetchurl {
              url = binaryUrl;
              hash = hashes.${hashKey};
            };
          in pkgs.stdenv.mkDerivation {
            pname = "factory-droid";
            inherit version;

            nativeBuildInputs = [ pkgs.makeWrapper ];
            buildInputs = [ pkgs.ripgrep ];

            dontUnpack = true;
            dontBuild = true;
            dontStrip = true;
            dontPatchELF = true;
            dontPatchShebangs = true;

            installPhase = ''
              mkdir -p $out/bin
              cp ${droidBinary} $out/bin/droid
              chmod +x $out/bin/droid
            '';

            postFixup = ''
              wrapProgram $out/bin/droid \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ripgrep ]}
            '';

            meta = with pkgs.lib; {
              description = "Factory Droid CLI - AI software engineering agent";
              homepage = "https://factory.ai";
              license = licenses.unfree;
              platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
              maintainers = [ ];
            };
          };
          default = packages.factory-droid;
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/droid";
        };
      }
    );
}
