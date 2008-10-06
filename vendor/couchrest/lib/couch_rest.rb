require 'rubygems'
require 'json'
require 'rest_client'
require 'addressable/uri'

$:.unshift File.dirname(__FILE__) + '/couch_rest'

require 'core_ext'

module CouchRest
  autoload :Server,       'server'
  autoload :Database,     'database'
  autoload :Pager,        'pager'
  autoload :FileManager,  'file_manager'

  # Shortcut for CouchRest::Server.new
  #
  # @param [String] server_uri The URI of the CouchDB server. defaults to "http://localhost:5984/"
  # @return CouchRest::Server
  def self.new(server_uri='http://localhost:5984/')
    Server.new(server_uri)
  end
end
