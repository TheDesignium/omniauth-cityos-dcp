# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rake/testtask'

RSpec::Core::RakeTask.new(:spec)

Rake::TestTask.new(:test) do |task|
  task.libs << 'lib'
  task.pattern = 'test/**/*_test.rb'
end

task default: [:spec, :test]
