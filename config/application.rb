require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kuroko2
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # MEMO:
    # Railsエンジン(kuroko2)で生成されたmigrationファイルを実行する時、
    # SCOPE=kuroko2 という環境変数を指定してdb:migrateを実行するのだが、
    # db:migrateで作成するテーブルに紐づいているモデル(Kuroko2::JobDefinition)に
    # 不具合がありモンキーパッチ(lib/monkey_patches/override_kuroko2_jd.rb)を当てたところ、
    # なぜかSCOPE=kuroko2の設定がなぜか無視されるようになってしまったので明示的に明示的にテーブル名のprefixを指定するしかなかった。
    # 不都合と言えば、新規テーブルを作成する時に「kuroko2_」というprefixができてしまう問題があるが
    # Railsエンジン(kuroko2)で生成されたmigrationファイル以外を追加する文化がなく実害はないと考えている。
    # kuroko2のバージョンが上がり、こちらの問題が解決したらこのコードは消してほしい。
    # https://github.com/cookpad/kuroko2/issues/125#issue-378985754
    config.active_record.table_name_prefix = 'kuroko2_'
    config.autoload_paths << Rails.root.join("lib")
  end
end
