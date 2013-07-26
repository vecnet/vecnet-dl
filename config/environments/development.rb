Resque.inline = true
Vecnet::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  config.log_level = :debug

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true

  #config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.application_url = "http://localhost:3000"

  config.default_characterization_runner = lambda { |file_path|
    Rails.root.join('spec/support/files/default_fits_output.xml').read
  }

  if ENV['FULL_STACK']
    require 'clamav'
    ClamAV.instance.loaddb
    config.default_antivirus_instance = lambda {|file_path|
      ClamAV.instance.scanfile(file_path)
    }
  else
    config.default_antivirus_instance = lambda {|file_path|
      AntiVirusScanner::NO_VIRUS_FOUND_RETURN_VALUE
    }
    config.default_characterization_runner = lambda { |file_path|
      Rails.root.join('spec/support/files/default_fits_output.xml').read
    }
  end

  config.action_mailer.smtp_settings = {
      enable_starttls_auto: true,
      address: "smtp.gmail.com",
      port: 587,
      domain: 'google.com',
      authentication: 'plain',
      user_name: "webhostingbanu@gmail.com",
      password:"shantivan",
  }

  config.pubtkt_public_key = %q{-----BEGIN PUBLIC KEY-----
MIIBtjCCASsGByqGSM44BAEwggEeAoGBAJTtmMTD+UnUUKu/tBPmIJhnPgFuFA6R
QjdZeyPozgL5Ob1usa2jW4lgQpx86zG6H7fCIacNem8cS0HwdizGXNX83hSJWoeA
DmlFH2+w11eRz2/+I0ugeeGjF19bJODt992jJ8SJoVsweCMgySmIK5UQlazfG0ed
w/5BrK3cKP3fAhUA4X3IpeWeK50mmSGCZhRFmokhnU8CgYBxbgkk7nMloLf+IiZo
kkCoIwlQ1u2hhMaj+7Ne/AXwWo97xcMHAqVAoLNZjI2VwUDmQOGxiUKpT//m97iZ
F8irH9aF4tw7ioHkbz53ApfNPRJGi4c/rNGoFVl9jmqKAaoP9HERYkqrvRuyBTVg
GeCwizPieorhbmLVYtAjaDLuAAOBhAACgYBM5gZ8oP/w5nf4080Wd0JcZOJYLtvo
/eeljOyIxtSpwoMGj0TNAq4ZcsG0Z4Yew/HCFvPfae62avUahan/GvMnrHeoD1Ko
iVGe5mWqSYduDIGs2aPvMMMfFQp8ZsODKu+YBPUf6M3g6CroOg32O88Efc5j4Ev9
Cgh/jB9nBWmVdA==
-----END PUBLIC KEY-----}
  config.pubtkt_login_url = 'http://localhost:3000/login'
end
