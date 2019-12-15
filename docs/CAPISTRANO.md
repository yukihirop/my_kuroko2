## Capistranoコマンドを使う時のTips

#### 前準備

githubとデプロイ先へのSSH鍵をssh-addしておく

```bash
# 私の環境の場合
{
  ssh-add ~/.ssh/id_rsa
  ssh-add ./certs/kuroko2_rsa
}
```

確認する。

```bash
$ ssh-add -l
2048 SHA256:E6faoiwfaoiwfhioawhfoaoifaoifoiaoafoiaoifa yukihirop@FukudanoMBP (RSA)
4096 SHA256:foawjfoaiwjgishgoiowhioffaiowfoiaiofaoihfa yukihirop@FukudanoMacBook-Pro.local (RSA)
```

#### 環境変数を更新した場合

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

#### systemdのファイルを更新した場合

```bash
{
  bundle exec cap production systemd:kuroko2-executor:setup systemd:kuroko2-processor:setup systemd:kuroko2-scheduler:setup
  bundle exec cap production deploy
}
```

#### 本番環境のrailsコンソールに入る場合

```
bundle exec cap production console
```

