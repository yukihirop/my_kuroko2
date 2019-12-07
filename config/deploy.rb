# config valid for current version and patch releases of Capistrano
lock "~> 3.11.2"

set :application, "my_kuroko2"
set :repo_url, "git@github.com:yukihirop/kuroko2.git"
set :branch, ENV.fetch('DEPLOY_BRANCH')
set :deploy_to, '/var/www/kuroko2'

set :linked_files, fetch(:linked_files, []).push('config/settings.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

set :keep_releases, 5
set :rbenv_ruby, '2.5.3'

set :bundle_jobs, 4
set :log_level, :debug

set :default_env, {
  SCOPE: 'kuroko2'
}

namespace :deploy do
  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart'
  end

  desc 'Create database'
  task :db_create do
    on roles(:db) do |host|
      with rails_env: fetch(:rails_env) do
        within current_path do
          execute :bundle, :exec, :rake, 'db:create'
        end
      end
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end
end
