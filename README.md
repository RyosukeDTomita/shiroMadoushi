# shiroMadoushi

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ABOUT

ふりかえり用のツールをまとめたモノレポ

- [Libra](./Libra/): トニーシュワルツの4つのエネルギー状態を判定するツール

---

## HOW TO USE

### Initial Set Up

```shell
nix develop
# direnvを使う場合
direnv allow
```

> [!NOTE]
> devShellに含まれるtricorderはhaskell.nixでビルドされるため、キャッシュ(`cache.iog.io` / `tweag-tricorder.cachix.org`)が使えないとGHCからのソースビルドになる。
> 初回の`nix develop`で`flake.nix`の`nixConfig`を受け入れるか、`nix.conf`に`extra-substituters` / `extra-trusted-public-keys`を追加しておく。

---

## FOR DEVELOPER

### formatter

- treefmt
  - ormolu
  - hlint(lintのみ。指摘があると失敗する)
  - nixfmt
  - mdformat
  - ghalint
  - pinact

> [!NOTE]
> pinactはGitHub APIを使うため、ネットワークの無い`nix flake check`ではpinactを除外している。

```shell
nix fmt
# ビルド・テスト・整形漏れ・hlint・cabal checkのチェック(CIでも実行)
nix flake check
```

### tricorder

ファイル変更を監視し、lib/exe/testを継続的にビルド・テストする(devShellに同梱)。設定は`.tricorder.yaml`。

```shell
tricorder ui
# 非対話で確認する場合
tricorder start
tricorder status
tricorder test suites
```

> [!NOTE]
> `.ghci`(ユーザーの`~/.ghci`があればそれも)は対話用のimportを含み、`cabal repl`で読み込むと失敗することがあるため、`.tricorder.yaml`で`-ignore-dot-ghci`を指定している。

### hoogle

devShellには依存ライブラリのドキュメント込みのHoogleが入っている。

```shell
hoogle server --local
```

### ライブラリの追加

- 使うパッケージの`<Dir>/<name>.cabal`の`build-depends`に足す。
  - `direnv`不使用の場合には再度`nix develop`する
  - `flake.nix`のdevShellは`hpkgs.shellFor`で`.cabal`から依存を読む
- パッケージはnixpkgs経由で取得し、Hackageからは取得しない。
  - `cabal.project`にもHackageを参照させないように設定済み
- .ghciでデフォルトでimportするライブラリは`/sync-ghci`SKILLSで行う。

### GHCのバージョンを上げる

`flake.nix`の`ghcVersion`を変更する(`hpkgs` / `packages.static` / `treefmt.nix`のormolu・hlintはここを参照する)。
各パッケージの`.cabal`の`base`の下限も合わせて変更する。
