$: << File.dirname(__FILE__) + '/vendor/couchrest/lib'

require 'rubygems'
require 'rake/testtask'
require 'rcov/rcovtask'
require 'couch_rest'

DatabaseName = 'saloonrb'
CollectionId = 'my_collection'

$couch = CouchRest.new
$database = $couch.database(DatabaseName)

desc 'Default: run all tests'
task :default => :test

task :test => [:"test:unit", :"test:integration"]

namespace :test do
  desc 'Run unit tests'
  task :unit do
    sh 'testrb test/*.rb'
  end

  desc 'Run integration tests using APE and open browser at the result page'
  task :integration => [:ape, :app] do
    validator = Ape::Ape.new(:output => 'html', :debug => false)
    validator.check('http://0.0.0.0:1234/')
    report = Tempfile.new('saloon')
    validator.report(report)
    report.close
    `open file://#{report.path}`
    Process.kill('KILL', $pid)
    Process.kill('KILL', app_pid)
  end

  task :ape do
    `git clone git://github.com/sr/ape.git` unless File.directory?('ape')

    require File.dirname(__FILE__) + '/ape/lib/ape'

    Ape::Ape.class_eval do
      alias :old_initialize :initialize

      def initialize(args); old_initialize(args); @dialogs = {}; end
    end
  end

  task :app do
    unless app_pid
      $pid = fork { `ruby lib/app.rb -p1234` }
      sleep 2
    end
  end

  def app_pid
    found = `ps ax`.grep(/ruby lib\/app\.rb/)
    return nil if found.empty?
    found.first.lstrip[0..3].to_i
  end
end

task :coverage => :"coverage:verify"

Rcov::RcovTask.new('coverage:generate') do |t|
  t.test_files = FileList['test/*_test.rb']
  t.rcov_opts << '-Ilib'
  t.rcov_opts << '-x"home"'
  t.verbose = true
end

namespace :coverage do
  task :verify => :generate do
    puts "TODO"
  end
end

namespace :database do
  desc 'Seed data into database'
  task :bootstrap => [:create, :"bootstrap:entries", :"bootstrap:views"]

  desc 'Re-create database'
  task :redo => [:destroy, :bootstrap]

  desc 'Create database'
  task :create do
    unless $couch.databases.include?(DatabaseName)
      puts "Creating database `#{DatabaseName}'"
      $couch.create_db(DatabaseName)
    end
  end

  desc 'Destroy database'
  task :destroy do
    if $couch.databases.include?(DatabaseName)
      puts "Destroying database `#{DatabaseName}`"
      $database.delete!
    end
  end

  namespace :bootstrap do
    desc 'Create sample collection'
    task :collections do
      3.times do |i|
        puts "Saving sample collection document #{i}"
        $database.save('_id' => "#{CollectionId}_#{i}",
          :type       => 'collection',
          :base       => "http://0.0.0.0:1234/#{CollectionId}_#{i}",
          :title      => "My AtomPub Collection #{i}",
          :authors    => [{:name => 'Simon Rozet', :uri => 'http://purl.org/net/sr/'}])
      end
    end

    desc 'Create samples entries'
    task :entries => :collections do
      puts 'Saving sample entries documents'
      5.times do |i|
        $database.save('_id' => "entry_#{i}",
          :collection => "#{CollectionId}_#{i}",
          :type       => 'entry',
          :links      => [{:rel => 'edit',
                          :href => "http://0.0.0.0:1234/#{CollectionId}_#{i}/entry_#{i}"}],
          :title      => "Sample Entry #{i}",
          :updated    => Time.mktime(2008, 1, 1+i),
          :edited     => Time.mktime(2008, 1, 1+i),
          :content    => "Content of the entry number #{i}.")
      end
    end

    desc 'Create views'
    task :views do
      sh File.dirname(__FILE__) + "/vendor/couchrest/bin/couch-view-push -a #{DatabaseName}"
    end
  end
end
