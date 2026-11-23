{
  description = "shiroMadoushi: Haskell monorepo (Nix flake)";

  # tricorderはhaskell.nixでビルドされるため、キャッシュが無いとGHCからソースビルドになる。
  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://tweag-tricorder.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "tweag-tricorder.cachix.org-1:PbwYPJ9gF8Wns14ai0sHK3iblqFd5YUrj0zEzGsJ/wg="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # GitHub Actionsメンテ用ツール(ghalint等)は新しいnixpkgsから取る。
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    # treefmt-nixが独自にnixpkgsを取得しないよう、こちらのnixpkgsに揃える。
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    # ghcideの代わりにtricoderを使う
    # キャッシュを効かせるため、nixpkgsはfollowsさせずtricorder側のものを使う。
    tricorder.url = "github:tweag/tricorder";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      treefmt-nix,
      tricorder,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        unstablePkgs = import nixpkgs-unstable { inherit system; };
        # GHCのバージョンはここで一元管理する(treefmt.nixのormolu / hlintにも渡す)。
        ghcVersion = "ghc9122";
        hpkgs = pkgs.haskell.packages.${ghcVersion};

        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          imports = [ ./treefmt.nix ];
          _module.args = { inherit unstablePkgs ghcVersion; };
        };
        # nix flake checkはサンドボックス内でネットワークが無く、GitHub APIを叩く
        # pinactは必ず失敗するため、チェック用の評価ではpinactだけ外す。
        treefmtCheckEval = treefmt-nix.lib.evalModule pkgs {
          imports = [ ./treefmt.nix ];
          _module.args = { inherit unstablePkgs ghcVersion; };
          programs.pinact.enable = pkgs.lib.mkForce false;
        };
        inherit (pkgs) lib;

        # モノレポのパッケージ一覧(cabalのパッケージ名 = ディレクトリ)。
        # パッケージを足したらこことcabal.projectのpackagesに追加する。
        packageDirs = {
          libra = ./Libra;
        };

        # .hs / .cabal だけをソースにし、README等を変えてもビルドのハッシュが変わらないようにする。
        mkSrc =
          dir:
          lib.fileset.toSource {
            root = dir;
            fileset = lib.fileset.fileFilter (file: file.hasExt "hs" || file.hasExt "cabal") dir;
          };

        # 依存は各パッケージの.cabalのbuild-dependsだけで管理する。
        # callCabal2nixがbuild-dependsをhpkgsの同名パッケージに解決する。
        haskellPackages = lib.mapAttrs (name: dir: hpkgs.callCabal2nix name (mkSrc dir) { }) packageDirs;

        # musl静的バイナリ
        staticPackages = lib.mapAttrs' (
          name: dir:
          lib.nameValuePair "${name}-static" (
            pkgs.haskell.lib.justStaticExecutables (
              pkgs.pkgsStatic.haskell.packages.${ghcVersion}.callCabal2nix name (mkSrc dir) { }
            )
          )
        ) packageDirs;

        cabalChecks = lib.mapAttrs' (
          name: dir:
          lib.nameValuePair "cabal-check-${name}" (
            pkgs.runCommand "cabal-check-${name}"
              {
                nativeBuildInputs = [ pkgs.cabal-install ];
              }
              ''
                export HOME=$TMPDIR
                cd ${mkSrc dir}
                cabal check
                touch $out
              ''
          )
        ) packageDirs;
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        # `nix flake check`はファイルを更新せず、チェックだけを行う。(主にCI)
        # checks.*で書かれたものが走る。
        # build-<name>: ビルドとtest-suite / cabal-check-<name>: cabal check / formatting: treefmt
        checks =
          lib.mapAttrs' (name: drv: lib.nameValuePair "build-${name}" drv) haskellPackages
          // cabalChecks
          // {
            formatting = treefmtCheckEval.config.build.check self;
          };

        # `nix build .#<name>`で実行バイナリを生成する(nix storeに動的リンクする開発用)。
        # `nix build`(default)は全パッケージをまとめたもの。
        # callCabal2nixはビルド時にtest-suiteも実行する。
        # `nix build .#<name>-static`でmusl静的バイナリ。
        packages =
          haskellPackages
          // staticPackages
          // {
            default = pkgs.symlinkJoin {
              name = "shiroMadoushi";
              paths = lib.attrValues haskellPackages;
            };
          };

        # cabalはHackageではなく、nixからパッケージを取得する
        devShells.default = hpkgs.shellFor {
          packages = _: lib.attrValues haskellPackages;
          # 依存ライブラリのドキュメント込みのローカルHoogleを使えるようにする(`hoogle server --local`)。
          withHoogle = true;
          nativeBuildInputs = [
            treefmtEval.config.build.wrapper
            pkgs.zsh
            hpkgs.haskell-language-server
            pkgs.cabal-install
            hpkgs.hlint
            tricorder.packages.${system}.tricorder
            unstablePkgs.pinact
            unstablePkgs.ghalint
          ];
        };
      }
    );
}
