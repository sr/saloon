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
  attr_reader :database_name

  def initialize(database_name)
    @database_name = database_name
  end

  def service
    service = Atom::Service.new
    workspace = service.workspaces.new

    database.view('collection/all')['rows'].each do |doc|
      collection = Atom::Collection.new(doc['value']['base'])
      collection.title = doc['value']['title']
      collection.accepts = 'application/atom+xml;type=entry'
      workspace.collections << collection
    end

    service
  end

  def find_collection(collection)
    documents = database.view('entry/by_collection',
      :startkey => [collection, 0], :endkey => [collection, 1])['rows']
    collection = atom_collection_from(documents) or raise CollectionNotFound
    entries    = atom_entries_from(documents).sort_by { |e| e.edited }.reverse

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

    document = database.save(entry.to_doc)
    # TODO: remove that hack
    entry.edit_url = (collection['value']['base'] + '/').to_uri.join(document['id']).to_s
    database.save entry.to_doc.update(
      '_id'  => document['id'],
      '_rev' => document['rev'],
      'type' => 'entry',
      'id'   => entry.edit_url,
      'collection' => collection['id']
    )

    entry
  end

  def update_entry(collection, entry, new_entry)
    entry = get_entry(collection, entry) or raise EntryNotFound
    new_entry = Atom::Entry.parse(new_entry)

    new_entry.id = entry['id']
    new_entry.edit_url = entry.to_atom_entry.edit_url
    new_entry.updated!
    new_entry.edited!

    database.save new_entry.to_doc.update(
      '_id'        => entry['_id'],
      '_rev'       => entry['_rev'],
      'collection' => entry['collection'],
      'type'       => 'entry'
    )

    new_entry
  end

  def delete_entry(collection, entry)
    entry = get_entry(collection, entry) or raise EntryNotFound
    database.delete(entry)
  end

  private
    def database
      @database ||= CouchRest.new.database(database_name)
    end

    def get(view, key)
      response = database.view(view, :key => key, :count => 1)
      response['rows'].empty? ? nil : response['rows'].first
    end

    def get_entry(collection, entry)
      entry = get('entry/by_collection_and_entry', [collection, entry])
      entry ? entry['value'] : nil
    end

    def atom_collection_from(documents)
      collection = documents.detect { |doc| doc['value']['type'] == 'collection' }
      collection ? collection['value'].to_atom_feed : nil
    end

    def atom_entries_from(documents)
      entries = documents.select { |doc| doc['value']['type'] == 'entry' }
      entries.any? ? entries.map { |doc| doc['value'].to_atom_entry } : nil
    end
end
