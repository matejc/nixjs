{ action ? "run" }:

let

  pkgs = import <nixpkgs> {};

  nodewebkit = pkgs.callPackage ./node-webkit.nix { gconf = pkgs.gnome.GConf; };

  nixui = pkgs.stdenv.mkDerivation rec {
    name = "nixui";
    src = [ { name = "nixui-src"; outPath = ./.; } ];
    buildInputs = [ pkgs.git pkgs.nodePackages.npm ];
    propagatedBuildInputs = [ pkgs.nix pkgs.nodejs ];
    buildPhase = "";
    installPhase = ''
      mkdir -p $out/bin
      cp -r $src/node_modules $out
      cp -r $src/bower_components $out
      cp -r $src/src $out
      cp -r $src/package.json $out

      cat > $out/bin/nixui <<EOF
      PATH="${pkgs.nix}/bin:\$PATH" ${nodewebkit}/bin/nw $out "\$@"
      EOF
      chmod +x $out/bin/nixui
    '';
  };

  dispatcher = action:
    if action == "env" then
      pkgs.stdenv.mkDerivation rec {
        name = "nixui-env";
        buildInputs = with pkgs; [ nodejs psmisc nettools nodewebkit
          nodePackages.npm2nix ];
        shellHook = ''
          export NODE_PATH="`pwd`/node_modules:$NODE_PATH"
        '';
      }
    else if action == "package" then
      pkgs.callPackage ./package.nix { node_webkit = nodewebkit; }
    else  # run
      pkgs.stdenv.mkDerivation rec {
        name = "nixui";
        src = nixui;
        buildInputs = with pkgs; [ psmisc nettools ];
        shellHook = ''
          ${nixui}/bin/nixui
        '';
      };

in dispatcher action
