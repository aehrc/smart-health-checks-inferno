# frozen_string_literal: true

require 'pry'
require 'pry-byebug'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError # rubocop:disable Lint/SuppressedException
end

namespace :db do
  desc 'Apply changes to the database'
  task :migrate do
    require 'inferno/config/application'
    require 'inferno/utils/migration'
    Inferno::Utils::Migration.new.run
  end
end

namespace :smart_health_checks do
  desc 'Generate tests'
  task :generate do
    require 'inferno_suite_generator'
    basic_config_file = './config.basic.json'
    config_files = ['./config.040.json']
    config_files.each do |config_file|
      InfernoSuiteGenerator::Generator.generate([basic_config_file, config_file])
    end
  end
end

namespace :dev_tools do
  desc 'Install or update the shared bin/hot-reload watcher script'
  task :install_hot_reload do
    require 'inferno_suite_generator/dev_tools/hot_reload_installer'

    installer = InfernoSuiteGenerator::DevTools::HotReloadInstaller.new
    result = installer.install!(force: ENV['FORCE'] == '1')

    case result
    when :installed
      puts "Installed bin/hot-reload (v#{installer.installed_version})."
      puts "Wire it into compose.yaml — see inferno_suite_generator's README 'Auto-reload' section."
    when :updated
      puts "Updated bin/hot-reload to v#{installer.installed_version}."
    when :up_to_date
      puts "bin/hot-reload is already up to date (v#{installer.installed_version})."
    end
  end
end
