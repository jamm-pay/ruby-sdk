# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'
require 'bundler/gem_tasks'

RuboCop::RakeTask.new

task default: %i[rubocop]

desc 'Run end-to-end tests'
Rake::TestTask.new(:e2e) do |t|
  t.pattern = './test.e2e/**/*_test.rb'
end
