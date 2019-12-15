# 1からGCPにデプロイするやり方 (例)

## 注意🚨

- 外部IPはエフェメラルでなく、静的IPなので注意(300円/月)
- ドメインyukihirop.meも課金対象(2500円/年)
- 使ってない時はVMインスタンスは停止するようにする

## compute engineの作成

`PROJECT_ID` と `SERVICE_ACCOUNT` を設定する。

```bash
gcloud beta compute \
  --project=${PROJECT_ID} instances create kuroko2-production --zone=asia-northeast2-b \
  --machine-type=n1-standard-1 \
  --subnet=default \
  --network-tier=PREMIUM \
  --maintenance-policy=MIGRATE \
  --service-account=${SERVICE_ACCOUNT} \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server,https-server \
  --image=debian-9-stretch-v20191121 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-standard \
  --boot-disk-device-name=kuroko2-production \
  --reservation-affinity=any
```

## ファイヤーウォールの作成

`PROJECT_ID` を設定する。

社内で使用する場合は、SOURCE_RANGESを社内ネットワークに限定する。

tcp/80,443を解放してます。

```bash
gcloud compute --project=${PROJECT_ID} firewall-rules create default-allow-http \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=${SOURCE_RANGES:-'0.0.0.0/0'} \
  --target-tags=http-server
```

```bash
gcloud compute --project=${PROJECT_ID} firewall-rules create default-allow-https \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:443 \
  --source-ranges=${SOURCE_RANGES:-'0.0.0.0/0'} \
  --target-tags=https-server
```

## ssh接続する

```bash
gcloud beta compute --project ${PROJECT_ID} ssh --zone "asia-northeast2-b" "kuroko2-production"
```

## rubyのインストール

#### rbenvのインストール

rbenvをビルドしたり、rubyをインストールしたりするための依存パッケージをインストールする必要がある。

```bash
sudo apt-get -y install git gcc make libssl-dev libreadline-dev zlib1g-dev bzip2
```

続いてrbenvのインストール

```bash
{
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  source ~/.bashrc
}

```

#### ruby-buildのインストール

複数のバージョンのrubyをインストールできるようにするためにはruby-buildが必要であるのでインストールする。

```bash
{
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
}
```

#### rubyのインストール

```bash
{
  rbenv install 2.5.3
  rbenv global 2.5.3
  rbenv rehash
}
```

もしこういう警告「perl: warning: Please check that your locale settings」が出る場合は、
ローケルの設定をし直す。

```bash
sudo locale-gen ja_JP.UTF-8
sudo dpkg-reconfigure locales
```

`ja_JP.UTF-8` を選択する。


確認する。

```
which ruby
```

#### bundlerのインストール

```
gem install bundler
```

## PostgreSQLの設定

```
sudo apt-get update && apt-get -y install libpq-dev postgresql postgresql-client
```

## nginxの設定

```bash
sudo apt-get update && apt-get -y install nginx
```

```bash
{
  cd /etc/nginx/conf.d
  sudo vi kuroko2.conf
}
```

以下のように書く

`<デプロイ先のIP>` は適切に書き換える。

```
error_log /var/www/kuroko2/current/log/nginx.error.log;
access_log /var/www/kuroko2/current/log/nginx.access.log;

client_max_body_size 2G;

upstream app_server {
  server unix:/var/www/kuroko2/current/tmp/sockets/.unicorn.sock fail_timeout=0;
}

server {
  listen 80;
  server_name <デプロイ先のIP>; 
  keepalive_timeout 5;
  root /var/www/kuroko2/current/public;

  try_files $uri/index.html $uri.html $uri @app;
  location @app {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://app_server;
  }

  error_page 500 502 503 504 /500.html;
  location = /500.html {
    root /var/www/kuroko2/current/public;
  }
}
```

nginxの再起動

```bash
# 自動起動の設定
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx
```

#### ExecJS用のランタイムのインストール

```
sudo apt-get -y install nodejs
```

参考
http://djandjan.hateblo.jp/entry/2018/07/25/224929

#### wheelグループにデプロイユーザーを追加

```bash
{
 sudo addgroup wheel
 sudo adduser $USER wheel  
}
```

#### postgresに繋がらない場合

```bash
yukihirop@kuroko2-production:~$ psql -U postgres
psql: FATAL:  Peer authentication failed for user "postgres"
```

こんな感じになったら以下のコマンドをうつ

```bash
sudo su postgres -c 'psql --username=postgres'
psql> ALTER USER postgres with encrypted password 'your_password';
```

さらに `pg_hba.conf` を修正する。

peerではなくmd5にする

```diff
- local all postgres peer
+ local all postgres md5
```

[参考](https://qiita.com/tomlla/items/9fa2feab1b9bd8749584)

postgresを再起動する。

```bash
sudo /etc/init.d/postgresql restart
```

## /etc/environmentの権限の編集

- 所有者とグループの編集
- 書き込み権限の編集

```bash
{
  sudo chown yukihirop:wheel /etc/environment
  sudo chmod g+w /etc/environment
}
```

## systemdサービスステータス確認

```bash
{
  sudo systemctl status my_kuroko2_kuroko2-processor.service
  sudo systemctl status my_kuroko2_kuroko2-scheduler.service
  sudo systemctl status my_kuroko2_kuroko2-executor.service
}
```
