require File.expand_path('lib/omniauth/strategies/village', Rails.root)

OmniAuth.config.on_failure = Proc.new do |env|
  SessionsController.action(:omniauth_failure).call(env)
  #this will invoke the omniauth_failure action in SessionsController.
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"]
end