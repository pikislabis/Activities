# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.11' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|

  config.gem "searchlogic"

  config.action_controller.session = {
    :key => '_activities_session',
    :secret      => 'f2f38d40a4d7dbb1a824b5c21918aeb9953f67b554d7900233bfac1d5d7a21bc85d2105ba65574e777a7339645e529f7ba66f1bfb1e208ce077821893dd16342'
  }

  config.time_zone = 'Madrid'

  config.active_record.observers = :user_observer, :incidence_observer
  config.i18n.default_locale = :es

end

require "will_paginate"
CalendarDateSelect.format = :finnish