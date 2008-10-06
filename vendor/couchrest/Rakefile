require 'rake'
require 'spec/rake/spectask'
require 'rcov/rcovtask'
require 'yard'

task :default => :test
task :test => [:"test:unit", :"test:integration"]

namespace :test do
  desc 'Run unit tests'
  task :unit do
    sh 'testrb test/*.rb'
  end

  desc "Run integration tests"
  Spec::Rake::SpecTask.new('integration') do |t|
    t.spec_files = FileList['spec/*_spec.rb']
  end
end

Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.rcov_opts << '-Ilib'
  t.rcov_opts << '-x"home"'
  t.verbose = true
end

YARD::Rake::YardocTask.new
