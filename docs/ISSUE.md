## unicorn:restartで環境変数が読み込まれない

```bash
# /etc/environmentを更新
bundle exec cap production deploy:env_sync
```

した後、サーバーに潜って

```bash
source '/etc/environment'
```

その後、デプロイ

```bash
UPDATE_ENV=true bundle exec cap production deploy
```
