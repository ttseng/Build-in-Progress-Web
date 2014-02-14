# Load the rails application
require File.expand_path('../application', __FILE__)

require 'hirb'
Hirb.enable
Hirb::Formatter.dynamic_config['ActiveRecord::Base']

# Initialize the rails application
Build::Application.initialize!