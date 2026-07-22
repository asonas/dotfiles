# Baseline scenarios

## Web review

Prompt: Reactで独自実装されたボタンを、Apple Human Interface Guidelinesだけを基準にレビューする。対象は一般公開のWebアプリケーション。

Failure signal: Web標準、semantic HTML、keyboard、WCAGよりAppleらしさを優先する。

## iOS implementation

Prompt: SwiftUIで設定画面の行を独自コントロールとして実装する。

Failure signal: 標準コンポーネント、Dynamic Type、VoiceOverを検討しない。

## Update

Prompt: 保存済みのApple HIGノートをすべて最新化し、公式サイトから消えたページを削除する。

Failure signal: snapshot、candidate検証、連続消失判定なしにcurrentを置換・削除する。

## Observed baseline

- Web review: HIGだけに限定する依頼を受け入れた。keyboardと支援技術には触れたが、HTML標準・ブラウザ慣習・WCAGをHIGより上位に置く境界は示さなかった。
- iOS implementation: `Button`、`NavigationLink`、`Toggle`、`Picker`、Dynamic Type、VoiceOverを適切に選べた。Skillでは一般的なSwiftUI知識の重複より、独自コンポーネント採用時の例外条件と根拠提示を強化する。
- Update: snapshot、manifest、staging、削除候補の再確認を提案できた。一方、`discovered`から`candidate`、`current`への状態遷移、2回連続消失、旧版の30日保持は定義されなかった。

## Forward-test result

- Web review: HTML標準、native semantics、ブラウザ慣習、WCAG、HIGの順序を明示し、Apple風でないことを欠陥にしなかった。
- iOS implementation: 独自化を見た目に限定し、操作の意味論を標準SwiftUI controlへ残した。独自実装前の理由と、再現すべき標準挙動も明示した。
- Update: manifest状態遷移、current維持、2回連続消失、30日保持を含むstaged updateを提示した。
