# SuperClaude ドキュメント

SuperClaudeプロジェクトの完全なドキュメントです。

## 📖 ドキュメント一覧

### 入門ガイド
- **[QUICKSTART.md](../QUICKSTART.md)** - 5分で始めるクイックスタート
- **[README.md](../README.md)** - プロジェクト概要
- **[CLAUDE.md](../CLAUDE.md)** - Claude Code向けガイドライン

### システム設計
- **[ARCHITECTURE.md](ARCHITECTURE.md)** 🏗️
  - システムアーキテクチャ全体像
  - コンポーネント設計
  - データフロー
  - セキュリティモデル
  - 拡張性と将来計画

### 開発者向け
- **[API_REFERENCE.md](API_REFERENCE.md)** 📚
  - Skills API完全リファレンス
  - 入出力仕様
  - エラーコード一覧
  - ベストプラクティス

- **[CLI_REFERENCE.md](CLI_REFERENCE.md)** 💻
  - execute-template.sh使用方法
  - コマンドラインオプション
  - 高度な使用例
  - バッチ処理パターン

- **[テンプレートガイド](../templates/README.md)** 📝
  - テンプレート作成方法
  - テンプレート構造
  - パラメータ定義

- **[スキルガイド](../skills/SKILLS_GUIDE.md)** 🔧
  - スキルの使用方法
  - 各スキルの詳細
  - 実行フロー

### 運用・保守
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** 🔍
  - よくある問題と解決方法
  - LocalStack関連
  - AWS/Azure CLI関連
  - デバッグTips

- **[テストガイド](../tests/README.md)** 🧪
  - テスト実行方法
  - 単体テスト
  - 統合テスト

## 🚀 学習パス

### 初めての方

1. **[README.md](../README.md)** でプロジェクト全体を理解
2. **[QUICKSTART.md](../QUICKSTART.md)** で実際に動かしてみる
3. **[SKILLS_GUIDE.md](../skills/SKILLS_GUIDE.md)** でスキルの使い方を学ぶ

### 開発者向け

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** でシステム設計を理解
2. **[API_REFERENCE.md](API_REFERENCE.md)** でAPI仕様を確認
3. **[テンプレートガイド](../templates/README.md)** で新しいテンプレート作成

### 運用担当者向け

1. **[CLI_REFERENCE.md](CLI_REFERENCE.md)** でCLIツールをマスター
2. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** でトラブルシューティング方法を習得
3. **[テストガイド](../tests/README.md)** でテスト実行方法を確認

## 📊 ドキュメント構成図

```
SuperClaude/
├── README.md                    # プロジェクト概要
├── QUICKSTART.md                # クイックスタート
├── CLAUDE.md                    # Claude向けガイド
│
├── docs/                        # 詳細ドキュメント
│   ├── README.md               # このファイル
│   ├── ARCHITECTURE.md         # システム設計
│   ├── API_REFERENCE.md        # API仕様
│   ├── CLI_REFERENCE.md        # CLI使用方法
│   └── TROUBLESHOOTING.md      # トラブルシューティング
│
├── templates/
│   └── README.md               # テンプレート作成ガイド
│
├── skills/
│   └── SKILLS_GUIDE.md         # スキル使用ガイド
│
└── tests/
    └── README.md               # テスト実行ガイド
```

## 🎯 用途別ガイド

### ケース1: 新しいリソースを作成したい
1. [SKILLS_GUIDE.md](../skills/SKILLS_GUIDE.md) の Provision Skill
2. [テンプレート一覧](../templates/) から適切なテンプレート選択
3. [API_REFERENCE.md](API_REFERENCE.md) でパラメータ確認

### ケース2: 既存リソースの情報を取得したい
1. [SKILLS_GUIDE.md](../skills/SKILLS_GUIDE.md) の Query Skill
2. [API_REFERENCE.md](API_REFERENCE.md#query-skill) でクエリタイプ確認

### ケース3: リソースの設定を変更したい
1. [SKILLS_GUIDE.md](../skills/SKILLS_GUIDE.md) の Configure Skill
2. [API_REFERENCE.md](API_REFERENCE.md#configure-skill) でアクション確認

### ケース4: 新しいテンプレートを作成したい
1. [ARCHITECTURE.md](ARCHITECTURE.md) でテンプレート構造理解
2. [テンプレートガイド](../templates/README.md) で作成方法確認
3. 既存テンプレートを参考にする

### ケース5: エラーが発生した
1. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) で該当するエラー検索
2. [CLI_REFERENCE.md](CLI_REFERENCE.md#トラブルシューティング) でデバッグ方法確認
3. ログを確認して原因特定

### ケース6: LocalStackでテストしたい
1. [QUICKSTART.md](../QUICKSTART.md#セットアップ初回のみ) でLocalStack起動
2. [CLI_REFERENCE.md](CLI_REFERENCE.md#setup-localstacksh) で詳細設定
3. [テストガイド](../tests/README.md) で統合テスト実行

## 🔗 外部リソース

### AWS
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [AWS Best Practices](https://aws.amazon.com/architecture/well-architected/)

### Azure
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)
- [Azure Best Practices](https://docs.microsoft.com/azure/architecture/best-practices/)

### ツール
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [YAML Specification](https://yaml.org/spec/)

## 💡 ベストプラクティス

### 開発時
- テンプレート作成後は必ず `validate` スキルでチェック
- LocalStackで動作確認してから本番環境へ
- パラメータはファイルで管理（バージョン管理）

### 運用時
- `--dry-run` で実行内容を事前確認
- 重要な操作は手動承認を挟む
- ログを保存して監査証跡を残す

### セキュリティ
- 認証情報はコードにハードコードしない
- 最小権限の原則に従う
- 本番環境では `--validate-only` で事前検証

## 🆘 サポート

### 問題が発生した場合

1. **ドキュメント確認**
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md) を確認

2. **テスト実行**
   ```bash
   ./tests/run-all-tests.sh
   ```

3. **ログ確認**
   - エラーメッセージの詳細を確認
   - デバッグモードで再実行

4. **Issue報告**
   - [GitHub Issues](https://github.com/your-repo/issues) で報告
   - エラーメッセージ、実行コマンド、環境情報を含める

### ドキュメントの改善提案

ドキュメントに不明点や改善提案がある場合：
- プルリクエストを送信
- Issueで提案

## 📄 ライセンス

MIT License - 詳細は [LICENSE](../LICENSE) を参照

## 🙏 貢献

ドキュメントの改善や追加は大歓迎です！

---

**最終更新**: 2026-02-08
**バージョン**: 1.0.0
