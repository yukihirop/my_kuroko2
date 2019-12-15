server ENV.fetch('DEPLOY_HOST'), user: ENV.fetch('DEPLOY_SSH_USER'), roles: %w{app db web}

set :ssh_options, {
  user: ENV.fetch('DEPLOY_SSH_USER'),
  keys: %w(~/.ssh/id_rsa "#{ENV.fetch('DEPLOY_SSH_KEY')}"),
  forward_agent: true,
  auth_methods: %w(publickey)
}
