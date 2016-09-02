# config/unicorn.rb
worker_processes 2
timeout 300
preload_app true

before_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

end

after_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end

 if defined?(ActiveRecord::Base)
    config = ActiveRecord::Base.configurations[Rails.env] ||
                Rails.application.config.database_configuration[Rails.env]
    config['pool']            =   ENV['DB_POOL'] || 2
    config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 300 # seconds
    ActiveRecord::Base.establish_connection(config)
  end
  
end