# optimizing-fp-and-proof-languages

Optimizing functional and proof languages with categorical and algebraic laws.

This repository contains the experiment code used in a Japanese article series on Qiita, in a form that can be reproduced.

## Article series

| No. | Title |
|---|---|
| 1 | [How category theory is used in optimizing Haskell](https://qiita.com/etale_cohomology/items/3377a23e45960eee4f25) |
| 2 | [Do the eight optimizations derived from category theory work outside Haskell?](https://qiita.com/etale_cohomology/items/79d8d6cf42f02fa80b7b) |
| 3 | [Optimizing proof languages from a categorical view: proofs disappear at runtime](https://qiita.com/etale_cohomology/items/7fdfc9088d24778e5ed9) |
| 4 | Where do categorical insights produce speed and correctness in finance, insurance, robotics, cryptography, and machine learning? |

## How to run

Verified with GHC 9.4.7. No external libraries are required; only those bundled with GHC are used.

```
ghc --version
```

### Code for article 4

| Chapter | File | Compile and run |
|---|---|---|
| 3 | `Float.hs` | `ghc -O2 Float.hs && ./Float` |
| 4 | `FreeDSL.hs` | `ghc -O2 -fno-full-laziness FreeDSL.hs && ./FreeDSL` |
| 4 | `Prob.hs` | `ghc -O2 Prob.hs && ./Prob` |
| 5 | `Sensor.hs` | `ghc -O2 -threaded -rtsopts Sensor.hs && ./Sensor` |
| 6 | `Field.hs` | `ghc -O2 Field.hs && ./Field` |
| 7 | `AD.hs` | `ghc -O2 AD.hs && ./AD` |
| 7 | `Mat.hs` | `ghc -O2 Mat.hs && ./Mat` |
| 8 | `CRT.hs` | `ghc -O2 CRT.hs && ./CRT` |

`Bench.hs` is a helper for timing. It is not meant to be run on its own.

### Files that should fail to compile

The following two files exist to confirm that a type error occurs. If they do not compile, they are working as intended.

| Chapter | File | What it checks |
|---|---|---|
| 6 | `FieldBad.hs` | Mixing elements of different moduli causes a type error |
| 7 | `MatBad.hs` | Multiplying matrices with mismatched dimensions causes a type error |

## Measurement

| Item | Details |
|---|---|
| Compiler | GHC 9.4.7 |
| Repetitions | Measured five times, median reported |
| Timing | `GHC.Clock.getMonotonicTimeNSec`, taken before and after the computation |

Chapter 4 uses `-fno-full-laziness` to prevent results from being reused. Chapter 5 uses `-threaded`.

Measured values depend on the environment. The ratios reported in the articles may not be reproduced exactly.

## License

MIT License

---

# 日本語

関数型言語と定理証明言語のコードを、圏論・代数の法則にもとづいて最適化する。その実験コードを収めています。

Qiita の連載記事で行った実機検証を、再現できる形で公開しています。

## 連載記事

| 回 | 表題 |
|---|---|
| 初回 | [Haskell の最適化に圏論はどう使われているか](https://qiita.com/etale_cohomology/items/3377a23e45960eee4f25) |
| 第2回 | [圏論から導かれた8つの高速化の手法は、Haskell の外でも効くのか](https://qiita.com/etale_cohomology/items/79d8d6cf42f02fa80b7b) |
| 第3回 | [圏論から考える定理証明言語の最適化 ── 証明は実行時に消える](https://qiita.com/etale_cohomology/items/7fdfc9088d24778e5ed9) |
| 第4回 | 圏論の知見は、金融・保険・ロボティクス・暗号・機械学習のどこで速さと正しさを生むのか |

## 動かし方

GHC 9.4.7 で確かめました。外部のライブラリは使っていません。GHC に付属するものだけで動きます。

```
ghc --version
```

### 第4回のコード

| 章 | ファイル | コンパイルと実行 |
|---|---|---|
| 第3章 | `Float.hs` | `ghc -O2 Float.hs && ./Float` |
| 第4章 | `FreeDSL.hs` | `ghc -O2 -fno-full-laziness FreeDSL.hs && ./FreeDSL` |
| 第4章 | `Prob.hs` | `ghc -O2 Prob.hs && ./Prob` |
| 第5章 | `Sensor.hs` | `ghc -O2 -threaded -rtsopts Sensor.hs && ./Sensor` |
| 第6章 | `Field.hs` | `ghc -O2 Field.hs && ./Field` |
| 第7章 | `AD.hs` | `ghc -O2 AD.hs && ./AD` |
| 第7章 | `Mat.hs` | `ghc -O2 Mat.hs && ./Mat` |
| 第8章 | `CRT.hs` | `ghc -O2 CRT.hs && ./CRT` |

`Bench.hs` は、時間を測るための補助です。単独では実行しません。

### コンパイルに失敗すれば、期待どおりのもの

次の2つは、**型エラーになることを確かめるためのファイル** です。コンパイルが通らなければ、意図したとおりに動いています。

| 章 | ファイル | 確かめること |
|---|---|---|
| 第6章 | `FieldBad.hs` | 異なる法の要素を混ぜると、型エラーになる |
| 第7章 | `MatBad.hs` | 次元の合わない行列の積が、型エラーになる |

## 測定について

| 項目 | 内容 |
|---|---|
| 処理系 | GHC 9.4.7 |
| 測定の回数 | 原則として5回測定し、中央値を示した |
| 時間の測り方 | `GHC.Clock.getMonotonicTimeNSec` で、計算の前後の時刻を取った |

第4章は、計算結果の使い回しを避けるため `-fno-full-laziness` を指定しています。第5章は `-threaded` を指定しています。

環境によって、測定値は変わります。記事に示した倍率も、同じ値になるとは限りません。

## ライセンス

MIT License
