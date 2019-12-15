# config valid for current version and patch releases of Capistrano
lock "~> 3.11.2"

set :application, "my_kuroko2"
set :repo_url, "git@github.com:yukihirop/kuroko2.git"
set :branch, ENV.fetch('DEPLOY_BRANCH')
set :deploy_to, '/var/www/kuroko2'

set :linked_files, fetch(:linked_files, []).push('config/database.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

set :keep_releases, 5
set :rbenv_ruby, '2.5.3'

set :bundle_jobs, 4
set :log_level, :debug

set :default_env, {
  SCOPE: 'kuroko2',
  PG_USER: ENV.fetch('PG_USER'),
  PG_PASSWORD: ENV.fetch('PG_PASSWORD'),
  PG_HOST: ENV.fetch('PG_HOST')
}

set :system_dir, '/etc/systemd/system'
set :systemd_services, fetch(:systemd_services, []).push("#{fetch(:application)}_kuroko2-executor", "#{fetch(:application)}_kuroko2-processor", "#{fetch(:application)}_kuroko2-scheduler")

namespace :deploy do
  desc 'Upload database.yml && secrets.yml'
  task :upload_linked_files do
    on roles(:app) do |host|
      if test "[ ! -d #{shared_path}/config ]"
        execute :sudo, :mkdir, "-p", "#{shared_path}/config"
      end
      upload!('config/database.yml', "#{shared_path}/config/database.yml")
      upload!('config/secrets.yml', "#{shared_path}/config/secrets.yml")
    end
  end
  before :starting, :upload_linked_files

  desc 'Restart application'
  task :restart do
    if ENV.fetch('UPDATE_ENV', 'false') == 'true'
      invoke 'unicorn:stop'
      invoke 'unicorn:start'
    else
      invoke 'unicorn:restart'
    end
  end

  desc 'Create database'
  task :db_create do
    on roles(:db) do |host|
      with rails_env: fetch(:rails_env) do
        within release_path do
          execute :bundle, :exec, :rake, 'db:create'
        end
      end
    end
  end
  before :migrate, :db_create

  after :publishing, :restart
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end

  task :init_permission do
    on release_roles :all do
      execute :sudo, :chown, '-R', "#{ENV.fetch('DEPLOY_SSH_USER')}:wheel", deploy_to
    end
  end
  before :starting, :init_permission

  task :env_sync do
    set :env_config_roles, [:web, :app]
    environment = Capistrano::EnvConfig::Environment.new
    environment.set('SECRET_KEY_BASE', ENV.fetch('SECRET_KEY_BASE'))
    environment.set('GOOGLE_CLIENT_ID', ENV.fetch('GOOGLE_CLIENT_ID'))
    environment.set('GOOGLE_CLIENT_SECRET', ENV.fetch('GOOGLE_CLIENT_SECRET'))
    environment.set('GOOGLE_HOSTED_DOMAIN', ENV.fetch('GOOGLE_HOSTED_DOMAIN'))
    environment.set('SLACK_WEBHOOK_URL', ENV.fetch('SLACK_WEBHOOK_URL'))
    environment.set('PG_USER', ENV.fetch('PG_USER'))
    environment.set('PG_PASSWORD', ENV.fetch('PG_PASSWORD'))
    environment.set('PG_HOST', ENV.fetch('PG_HOST'))
    environment.sync
  end
  before :set_rails_env, :env_sync

  task :start_processes do
    on roles(:app) do |host|
      execute :sudo, :systemctl, 'daemon-reload'
      execute :sudo, :systemctl, :restart, fetch(:systemd_services)
    end
  end
  after :finished, :start_processes
end
