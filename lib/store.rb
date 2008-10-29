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
    documents = database.view('entry/by_collection',
      :startkey => [collection, 0], :endkey => [collection, 1])['rows']
    collection = atom_collection_from(documents) or raise CollectionNotFound
    entries    = atom_entries_from(documents)

    entries.inject(collection) do |collection, entry|
      collection.entries << entry
      collection
    end
  end

  def find_entry(collection, entry)
    entry = get_entry(collection, entry) or raise EntryNotFound
    entry.to_atom_entry
  end

  def create_entry(collection, entry)
    collection = get('collection/all', collection) or raise CollectionNotFound

    entry = Atom::Entry.parse(entry)
    entry.published!
    entry.updated!
    entry.edited!

    document = database.save(entry.to_h)
    # TODO: remove that hack
    entry.edit_url = (collection['value']['base'] + '/').to_uri.join(document['id']).to_s
    database.save entry.to_h.update(
      :_id => document['id'],
      :_rev => document['rev'],
      :type => 'entry',
      :id   => entry.edit_url,
      :collection => collection['id']
    )
    entry
  end

  def update_entry(collection, entry, new_entry)
    entry = get_entry(collection, entry) or raise EntryNotFound
    new_entry = Atom::Entry.parse(new_entry)
    new_entry.id = entry['id']
    new_entry.updated!
    new_entry.edited!
    database.save(new_entry.to_h)
  end

  def delete_entry(collection, entry)
    entry = get_entry(collection, entry) or raise EntryNotFound
    database.delete(entry)
  end

  protected
    def get(view, key)
      response = database.view(view, :key => key, :count => 1)
      response['rows'].empty? ? nil : response['rows'].first
    end

    def get_entry(collection, entry)
      entry = get('entry/by_collection_and_entry', [collection, entry])
      entry ? entry['value'] : nil
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
