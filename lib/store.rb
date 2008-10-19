$:.unshift File.dirname(__FILE__) + '/../vendor/couchrest/lib'

require 'rubygems'
require 'couch_rest'
require 'atom/service'
require 'atom/collection'
require 'atom/entry'

require File.dirname(__FILE__) + '/core_ext'

class CollectionNotFound < RuntimeError; end
class EntryNotFound < RuntimeError; end

class Store
  attr_reader :db_name

  def initialize(db_name)
    @db_name = db_name
  end

  def service
    service = Atom::Service.new
    workspace = service.workspaces.new
    database.view('collection/all')['rows'].each do |row|
      collection = Atom::Collection.new(row['value']['base'])
      collection.title = row['value']['title']
      collection.accepts = 'application/atom+xml;type=entry'
      workspace.collections << collection
    end
    service
  end

  def find_collection(collection)
    rows = database.view('entry/by_collection',
      :startkey => [collection, 0], :endkey => [collection, 1])['rows']
    raise CollectionNotFound unless atom_collection = atom_collection_from(rows)
    atom_entries_from(rows).inject(atom_collection) do |collection, entry|
      collection.entries << entry
      collection
    end
  end

  def find_entry(collection, entry)
    get_entry(collection, entry) || raise(EntryNotFound)
  end

  def create_entry(collection_id, entry)
    raise CollectionNotFound unless collection = get_collection(collection_id)
    entry = Atom::Entry.parse(entry)
    entry.published! && entry.updated! && entry.edited!
    doc = database.save(entry.to_h)
    # TODO: remove that hack
    entry.edit_url = (collection.base + '/').to_uri.join(doc['id']).to_s
    database.save(entry.to_h.update(:_id => doc['id'],
      :_rev => doc['rev'],
      :type => 'entry',
      :id   => entry.edit_url,
      :collection => collection_id
    ))
    entry
  end

  def update_entry(collection, entry, new_entry)
    raise EntryNotFound unless entry = get_entry(collection, entry)
    new_entry = Atom::Entry.parse(new_entry)
    new_entry.updated! && new_entry.edited!
    database.save(new_entry.to_h)
  end

  protected
    def get_collection(collection)
      collection = get('collection/all', collection)
      collection ? collection['value'].to_atom_feed : nil
    end

    def get_entry(collection, entry)
      entry = get('entry/by_collection_and_entry', [collection, entry])
      entry ? entry['value'].to_atom_entry : entry
    end

    def get(view, key)
      response = database.view(view, :key => key, :count => 1)
      response['rows'].empty? ? nil : response['rows'].first
    end

    def atom_collection_from(rows)
      collection = rows.detect { |row| row['value']['type'] == 'collection' }
      collection ? collection['value'].to_atom_feed : nil
    end

    def atom_entries_from(rows)
      entries = rows.select { |row| row['value']['type'] == 'entry' }
      entries.any? ? entries.map { |row| row['value'].to_atom_entry } : nil
    end

  private
    def server
      @server ||= CouchRest.new
    end

    def database
      @database ||= server.database(db_name)
    end
end
