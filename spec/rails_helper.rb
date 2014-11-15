# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'email_spec'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end
Capybara.register_driver :webkit_dev_null do |app|
  Capybara::Driver::Webkit.new(app, stdout: nil)
end
Capybara::Screenshot.class_eval do
  register_driver(:webkit_dev_null) do |driver, path|
    driver.render(path)
  end
end
Capybara.javascript_driver = :webkit

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.order = "random"
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  #config.use_transactional_fixtures = true
  
  config.include Capybara::DSL
  config.include Devise::TestHelpers, type: :controller
  config.include EmailSpec::Helpers
  config.include EmailSpec::Matchers
  #config.include Warden::Test::Helpers

  config.before(:suite) do
    begin
      DatabaseCleaner.start
    ensure
      DatabaseCleaner.clean
    end
  end
end

Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, browser: :chrome)
end
