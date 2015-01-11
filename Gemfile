source 'https://rubygems.org'

ruby '2.1.3'

gem 'rails', '4.1.6'

group :production, :staging, :development do
  gem 'comm', path: "comm"
end

gem 'mysql2'
gem 'haml'                                 
gem 'haml-rails'                                       
gem 'resque-scheduler' 
gem 'leaflet-rails'
gem 'devise'
gem "devise-async"
gem "paperclip", "~> 4.2"
gem "geocoder"
gem 'rails-i18n', github: 'svenfuchs/rails-i18n'

#assets
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery_mobile_rails'
gem 'swiper-rails'
gem 'modernizr-rails'

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
  gem 'sass-rails'
  gem 'bootstrap-sass'
  gem 'autoprefixer-rails'
  #gem 'coffee-rails'
  gem 'uglifier'
#end
gem 'coffee-rails'

group :staging do
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'capybara-webkit'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
end

#group :staging, :development do
group :production, :staging, :development do
  # Faye
  gem 'thin'
end

group :test, :development do
  gem 'awesome_print'
  gem 'email_spec'
  gem 'pry-nav'
  gem 'pry-rails', git: 'git://github.com/rweng/pry-rails.git'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'rspec-rails'
  gem 'shoulda-matchers'  # Shoulda Matchers for RSpec
  gem 'timecop'
end
