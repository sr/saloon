require 'rubygems'
require 'test/spec'
require 'mocha'

require File.dirname(__FILE__) + '/../lib/couch_rest'

begin
  CouchHost     = 'http://0.0.0.0:5984'
  TestDatabase  = 'couchrest-test'
end unless defined?(CouchHost)
