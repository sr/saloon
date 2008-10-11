$: << File.dirname(__FILE__) + '/vendor/couchrest/lib'

require 'rubygems'
require 'rake/testtask'
require 'rcov/rcovtask'
require 'couch_rest'

DatabaseName = 'saloonrb'
CollectionId = 'my_collection'

$couch = CouchRest.new
$database = $couch.database(DatabaseName)

task :default => :test

task :test do
  sh 'testrb test/*.rb' end

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
          :title      => "Sample Entry #{i}",
          :updated    => Time.mktime(2008, 1, 1+i),
          :content    => "Content of the entry number #{i}.")
      end
    end

    desc 'Create views'
    task :views do
      sh File.dirname(__FILE__) + "/vendor/couchrest/bin/couch-view-push -a #{DatabaseName}"
    end
  end
end
