# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'
require 'bundler/gem_tasks'

RuboCop::RakeTask.new

task default: %i[rubocop test]

desc 'Run unit tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = './test/**/*_test.rb'
end

desc 'Run end-to-end tests'
Rake::TestTask.new(:e2e) do |t|
  t.pattern = './test.e2e/**/*_test.rb'
end
