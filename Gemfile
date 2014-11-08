source 'https://rubygems.org'

gem 'rails', '3.2.14'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
gem 'comm', path: "comm"
gem 'haml', '>= 3.0.0'                                  
gem 'haml-rails'                                       
gem 'resque-scheduler' 
gem 'leaflet-rails'

#assets
gem 'jquery-rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :test, :development do
  gem 'awesome_print'
  gem 'pry-nav'
  gem 'pry-rails', git: 'git://github.com/rweng/pry-rails.git'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'rspec-rails'
  gem 'shoulda-matchers'  # Shoulda Matchers for RSpec
end
