# my kuroko2

## 注意🚨(自分向け)

- 外部IPはエフェメラルでなく、静的IPなので注意(300円/月)
- ドメインyukihirop.meも課金対象(2500円/年)
- 使ってない時はVMインスタンスは停止するようにする

## 開発環境

- Rails (5.1.7)
- ruby (ruby 2.5.3p105 (2018-10-18 revision 65156) [x86_64-darwin18])
- psql (PostgreSQL) 11.5
- kuroko2 (0.5.2)

## 環境構築

`.env` ファイルを用意する。

```bash
touch .env.sample .env
```

GSuiteのメールアドレスでgoogle_oauth2認証が使えるように適切に設定する。
(GSuiteしか対応してないです。Gmailでは認証不可です。)

```bash
bundle install --path vendor/bundle
bundle exec rails db:create
SCOPE=kuroko2 bundle exec rails db:migrate
bundle exec foreman start
```

Railsエンジンによって生成されたmigrationファイル(*.kuroko2.rb)のmigrationを
実行する時には `SCOPE` という環境変数にエンジン名(kuroko2)というのを指定する必要がある。
(今現在は[こちら](https://github.com/yukihirop/kuroko2/blob/master/config/application.rb#L28)でtable_name_prefixを指定しているので必須ではないが、この設定は将来的に削除する予定なのでつけないといけないと覚えておいたがいいです。)

以下のようなテーブルが作成できたら成功

```
mysql> show tables;
+---------------------------------+
| Tables_in_kuroko2_development   |
+---------------------------------+
| kuroko2_admin_assignments       |
| kuroko2_ar_internal_metadata    |
| kuroko2_execution_histories     |
| kuroko2_executions              |
| kuroko2_job_definition_tags     |
| kuroko2_job_definitions         |
| kuroko2_job_instances           |
| kuroko2_job_schedules           |
| kuroko2_job_suspend_schedules   |
| kuroko2_logs                    |
| kuroko2_memory_consumption_logs |
| kuroko2_memory_expectancies     |
| kuroko2_process_signals         |
| kuroko2_schema_migrations       |
| kuroko2_script_revisions        |
| kuroko2_stars                   |
| kuroko2_tags                    |
| kuroko2_ticks                   |
| kuroko2_tokens                  |
| kuroko2_users                   |
| kuroko2_workers                 |
+---------------------------------+
21 rows in set (0.00 sec)
```

## dockerで開発する

google_oauth2のcallbackURL( `http://127.0.0.1:3000/auth/google_oauth2/callback` )を設定する。

envファイルを用意する。

```
touch .env.sample .env.dev
```

```
docker-compose build

# この二つのコマンド実行には時間がかかる。原因はわかってない。
docker run app bundle exec rails db:create
docker run app bundle exec rails db:migrate SCOPE=kuroko2

docker-compose up -d
```

起動を確認する。

```
docker-compose ps
```

## 設定の仕方

公式ドキュメントを参考にしてください。
https://github.com/cookpad/kuroko2/blob/master/docs/index.md

## 注意事項

`Kuroko2::JobDefinition#save_and_record_revision` が正しく機能してなかったので[モンキーパッチ](https://github.com/yukihirop/kuroko2/blob/master/lib/monkey_patches/override_kuroko2_jd.rb)を当てています。このモンキーパッチを当てたことでdb:migrateを実行する際に指定するSCOPE=kuroko2という設定が無視されるようになってしまったので、[table_name_prefixの設定](https://github.com/yukihirop/kuroko2/blob/master/config/application.rb#L28)をしています。

## 備考

開発環境のテーブルの保護機能が働いて消せない警告が発生した場合は、`DISABLE_DATABASE_ENVIRONMENT_CHECK=1` を指定して行う。

```
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:drop
```

