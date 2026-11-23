# Libra

4つのエネルギー(身体・感情・思考・精神)それぞれについて、気持ち(positive / negative)とエネルギー量(high / low)を質問し、どのゾーンにいるかをMarkdownのリストで表示するCLI。

| | high | low |
|---|---|---|
| positive | パフォーマンス活動ゾーン | リニューアルゾーン |
| negative | サバイバルゾーン | バーンアウトゾーン |

## 使い方

リポジトリのルートで実行する。

```shell
cabal run libra
```

質問には`l`(左の選択肢)か`r`(右の選択肢)で答える。それ以外を入力すると同じ質問をもう一度出す。

```text
身体状態: Valence: positive or negative? (l/r) l
身体状態: Energy: high or low? (l/r) l
...
- 身体エネルギー: パフォーマンス活動ゾーン
- 感情エネルギー: リニューアルゾーン
- 思考エネルギー: サバイバルゾーン
- 精神エネルギー: リニューアルゾーン
```

## 構成

- `src/Libra.hs`: 型・ゾーン判定・表示用文字列の生成・入力の解析(純粋な関数)
- `app/Main.hs`: 質問と入出力
- `test/Spec.hs`: hspecのテスト
