$:.unshift File.dirname(__FILE__) + '/../vendor/couchrest/lib'

require 'rubygems'
require 'couch_rest'
require 'atom/entry'
require 'atom/collection'

require File.dirname(__FILE__) + '/core_ext'

class CollectionNotFound < RuntimeError; end
class EntryNotFound < RuntimeError; end

class Store
  attr_reader :db_name

  def initialize(db_name)
    @db_name = db_name
  end

  def find_collection(collection)
    document = get('collection/all', collection)
    raise CollectionNotFound unless document
    document.to_atom_feed
  end

  def find_entry(collection, entry)
    document = get('entry/by_collection', [collection, entry])
    raise EntryNotFound unless document
    document.to_atom_entry
  end

  def create_entry(collection, entry)
    find_collection(collection)
    entry = Atom::Entry.parse(entry)
    database.save(entry.to_h.merge!(:type => 'entry', :collection => collection))
  end

  protected
    def get(view, key)
      response = database.view(view, :key => key, :count => 1)
      response['rows'].empty? ? nil : response['rows'].first
    end

  private
    def server
      @server ||= CouchRest.new
    end

    def database
      @database ||= server.database(db_name)
    end
end
