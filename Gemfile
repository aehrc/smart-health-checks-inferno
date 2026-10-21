# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.6'

gemspec

group :development, :test do
  gem 'debug'
  gem 'minitest'
end

# Temporary: the plugin system lives on packages-system until it is merged to main.
gem 'inferno_suite_generator', github: 'hl7au/inferno_suite_generator', branch: 'packages-system'
gem 'pg', '~> 1.5'
gem 'rubocop', '~> 1.63.2'
gem 'rubocop-erb', '~> 0.3.0'
gem 'sqlite3', '~> 1.4'
