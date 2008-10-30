require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/store'

describe 'Store' do
  setup do
    @database = stub('couchdb database', :view => '', :save => '', :delete => '')
    @store = Store.new(TestDatabase)
    @store.stubs(:database).returns(@database)
    @rows = [
      { 'id' => 'my_collection',
        'key' => ['my_collection', 0],
        'value' => {'_id' => 'my_collection', 'type' => 'collection',
        'title' => 'My AtomPub Collection'}},
      { 'id' => 'my_entry',
        'key' => ['my_collection', 1],
        'value' => {'_id' => 'my_entry_2', 'type' => 'entry',
                    'title' => 'Entry 1', 'content' => 'foobar'}},
      { 'id' => 'my_entry',
        'key' => ['my_collection', 1],
        'value' => {'_id' => 'my_entry_2', 'type' => 'entry',
                    'title' => 'Entry 2', 'content' => 'foobar'}}
    ]
  end

  it 'has a  db_name' do
    @store.db_name.should.equal TestDatabase
  end

  describe 'Helpers' do
    setup do
      Store.class_eval do
        public :server, :database
        public :get_entry, :get
        public :atom_entries_from, :atom_collection_from
      end

      @store = Store.new(TestDatabase)
      @store.stubs(:database).returns(@database)
    end

    specify '#server returns a new CouchRest object' do
      CouchRest.expects(:new)
      Store.new(TestDatabase).server
    end

    specify '#database returns a new CouchRest::Database object' do
      Store.class_eval { public :database }
      store = Store.new(TestDatabase)
      store.database.should.be.an.instance_of(CouchRest::Database)
      store.database.name.should.equal TestDatabase
    end

    describe '#get' do
      it 'query the given view with the given key and limit to a single row' do
        @database.expects(:view).with('my_view/all', :key => 'the key', :count => 1).
          returns('rows' => [])
        @store.get('my_view/all', 'the key')
      end

      it 'returns the first row' do
        @database.stubs(:view).returns('rows' => ['foo', 'bar'])
        @store.get('my_view/all', 'the key').should.equal 'foo'
      end

      it 'returns nil if no document was found' do
        @database.stubs(:view).returns('rows' => [])
        @store.get('my_view/all', 'the key').should.be.nil
      end
    end

    describe '#get_entry' do
      setup do
        @entry = {:title => 'foo', :content => 'bar'}
        @row = {'id' => 'my_entry', 'value' => @entry}
        @entry.stubs(:to_atom_entry).returns(Atom::Entry.new)
        @store.stubs(:get).returns(@row)
      end

      it 'gets the view "entry/by_collection_and_entry' do
        @store.expects(:get).with('entry/by_collection_and_entry',
          ['my_collection', 'my_entry']).returns(@row)
        @store.get_entry('my_collection', 'my_entry')
      end

      it 'returns nil if no entry was found' do
        @store.stubs(:get).returns(nil)
        @store.get_entry('my_collection', 'my_entry').should.be.nil
      end
    end

    describe '#atom_collection_from' do
      it 'extracts the first row that is a collection an returns an Atom::Feed' do
        @store.atom_collection_from(@rows).should.be.an.instance_of(Atom::Feed)
        @store.atom_collection_from(@rows).title.to_s.should.equal 'My AtomPub Collection'
      end

      it 'returns nil if no collection was found' do
        @store.atom_collection_from([]).should.be.nil
      end
    end

    describe '#atom_entries_from' do
      it 'finds two entries' do
        @store.atom_entries_from(@rows).length.should.equal 2
      end

      it 'returns Atom::Entry-ies' do
        @store.atom_entries_from(@rows).each { |e| e.should.be.an.instance_of(Atom::Entry) }
        @store.atom_entries_from(@rows).first.title.to_s.should.equal 'Entry 1'
        @store.atom_entries_from(@rows).last.title.to_s.should.equal 'Entry 2'
      end

      it 'returns nil if no entries were found' do
        @store.atom_entries_from([]).should.be.nil
      end
    end
  end

  describe 'When getting service document' do
    setup do
      @rows = [{'id' => 'my_collection', 'value' => {'title' => 'foo',
        'base' => 'http://example.org/my_collection'}}]
      @database.stubs(:view).returns('rows' => @rows)
      @workspace  = Atom::Workspace.new
      @workspaces = stub('atom workspaces', :new => @workspace)
      @service = Atom::Service.new
      @service.stubs(:workspaces).returns(@workspaces)
      Atom::Service.stubs(:new).returns(@service)
    end

    it 'creates a new service document' do
      Atom::Service.expects(:new).returns(Atom::Service.new)
      @store.service
    end

    it 'creates a new workspace' do
      @service.workspaces.expects(:new).returns(Atom::Workspace.new)
      @store.service
    end

    it 'retrieves collections using the view collection/all' do
      @database.expects(:view).with('collection/all').returns('rows' => [])
      @store.service
    end

    it 'creates a collection and appends it to the workspace' do
      collection = Atom::Collection.new
      Atom::Collection.expects(:new).with('http://example.org/my_collection').
        returns(collection)
      collection.expects(:title=).with('foo')
      collection.expects(:accepts=).with('application/atom+xml;type=entry')
      @workspace.collections.expects(:<<).with(collection)
      @store.service
    end

    it 'returns the service document' do
      @store.service.should.be.an.instance_of Atom::Service
    end
  end

  describe 'When finding a collection' do
    def do_find
      @store.find_collection('my_collection')
    end

    setup do
      @database.stubs(:view).returns('rows' => @rows)
    end

    it 'finds the collection using the view entry/by_collection' do
      @database.expects(:view).with('entry/by_collection',
        :startkey => ['my_collection', 0], :endkey => ['my_collection', 1]).
        returns('rows' => @rows)
      do_find
    end

    it 'extracts the collection from the result set' do
      @store.expects(:atom_collection_from).with(@rows).returns(Atom::Feed.new)
      do_find
    end

    it 'extracts the entries from the result set' do
      @store.expects(:atom_entries_from).with(@rows).returns([Atom::Entry.new, Atom::Entry.new])
      do_find
    end

    it 'returns an Atom::Feed with the entries' do
      do_find.should.be.an.instance_of(Atom::Feed)
      do_find.entries.length.should.equal 2
      do_find.entries.first.title.to_s.should.equal 'Entry 1'
      do_find.entries.last.title.to_s.should.equal 'Entry 2'
    end

    it 'raises CollectionNotFound if no collection were found' do
      @store.stubs(:atom_collection_from).returns(nil)
      lambda { do_find }.should.raise CollectionNotFound
    end
  end

  describe 'When finding an entry' do
    def do_find
      @store.find_entry('my_collection', 'my_entry')
    end

    setup do
      @store.stubs(:get_entry).returns(:title => 'foo', :content => 'bar')
    end

    it 'gets the entry' do
      @store.expects(:get_entry).with('my_collection', 'my_entry').
        returns(:title => 'foo', :content => 'bar')
      do_find
    end

    it 'coerces the document to an Atom::Entry' do
      entry = stub('some entry')
      @store.stubs(:get_entry).returns(entry)
      entry.expects(:to_atom_entry)
      do_find
    end

    it 'raises EntryNotFound if no entry was found' do
      @store.stubs(:get_entry).returns(nil)
      lambda { do_find }.should.raise(EntryNotFound)
    end
  end

  describe 'When creating an entry' do
    def do_create
      @store.create_entry('my_collection', @entry.to_s)
    end

    setup do
      @collection = { 'id'    => 'my_collection',
                      'value' => { 'base' => 'http://foo.org/my_collection' } }
      @entry = Atom::Entry.new(:title => 'foo', :content => 'bar')
      @hash  = {:title => 'foo', :content => 'bar'}
      Atom::Entry.stubs(:parse).returns(@entry)
      @entry.stubs(:to_h).returns(@hash)
      @store.stubs(:get).returns(@collection)
      @database.stubs(:save).returns('id' => 1234)
    end

    it 'gets the collection' do
      @store.expects(:get).with('collection/all', 'my_collection').
        returns(@collection)
      do_create
    end

    it 'raises CollectionNotFound if no collection was found' do
      @store.stubs(:get).returns(nil)
      lambda { do_create }.should.raise(CollectionNotFound)
    end

    it 'parses the entry' do
      Atom::Entry.expects(:parse).with(@entry.to_s).returns(@entry)
      do_create
    end

    it 'sets the app:edited element to now' do
      @entry.expects(:edited!)
      do_create
    end

    it 'sets the updated element to now' do
      @entry.expects(:updated!)
      do_create
    end

    it 'sets the published element to now' do
      @entry.expects(:published!)
      do_create
    end

    it 'coerces the parsed entry to an hash and saves it' do
      @entry.expects(:to_h).returns(@hash)
      @database.expects(:save).with(@hash).returns('id' => 1234, 'rev' => 3456)
      do_create
    end

    it 'sets the entry edit_url using the returned id for the saved entry' do
      @collection['value'].expects(:[]).with('base').returns('http://foo.org/my_collection')
      @entry.expects(:edit_url=).with('http://foo.org/my_collection/1234')
      do_create
    end

    it 'sets the entry id using the edit url' do
      hash = {}
      @entry.stubs(:to_h).returns(hash)
      @entry.expects(:edit_url).returns('entry edit url')
      do_create
      hash['id'].should.equal 'entry edit url'
    end

    it 'sets the document id' do
      hash = {}
      @database.stubs(:save).returns('id' => 1234)
      @entry.stubs(:to_h).returns(hash)
      do_create
      hash['_id'].should.equal 1234
    end

    it 'sets the document revision' do
      hash = {}
      @database.stubs(:save).returns('rev' => 3455)
      @entry.stubs(:to_h).returns(hash)
      do_create
      hash['_rev'].should.equal 3455
    end

    it 'sets the type of the document to "entry"' do
      hash = {}
      @entry.stubs(:to_h).returns(hash)
      do_create
      hash['type'].should.equal 'entry'
    end

    it 'sets the collection to which the entry belongs' do
      hash = {}
      @entry.stubs(:to_h).returns(hash)
      do_create
      hash['collection'].should.equal 'my_collection'
    end

    it 'saves the hash to the database' do
      hash = stub('final hash', :update => 'foo')
      @entry.stubs(:to_h).returns({}, hash)
      @database.expects(:save).with('foo')
      do_create
    end

    it 'returns the entry' do
      do_create.should.equal @entry
    end
  end

  describe 'When updating an entry' do
    def do_update
      @store.update_entry('my_collection', 'my_entry', @new_entry.to_s)
    end

    setup do
      @entry = {'_id' => 'my_entry', '_rev' => 1234, 'collection' => 'my_collection'}
      @new_entry = Atom::Entry.new(:title => 'foo', :content => 'bar')
      Atom::Entry.stubs(:parse).returns(@new_entry)
      @store.stubs(:get_entry).returns(:id => 'document id')
    end

    it 'parses the new entry' do
      Atom::Entry.expects(:parse).with(@new_entry.to_s).returns(@new_entry)
      do_update
    end

    it 'gets the entry to update' do
      @store.expects(:get_entry).with('my_collection', 'my_entry').
        returns(:id => 'document id')
      do_update
    end

    it 'raises EntryNotFound if no entry was found' do
      @store.stubs(:get_entry).returns(nil)
      lambda { do_update }.should.raise(EntryNotFound)
    end

    it 'marks the new entry as edited' do
      @new_entry.expects(:edited!)
      do_update
    end

    it 'marks the new entry as updated' do
      @new_entry.expects(:updated!)
      do_update
    end

    it 'coerces to updated entry to an hash' do
      @new_entry.expects(:to_h).returns(:title => 'foo', :content => 'bar')
      do_update
    end

    it 'updates the document' do
      # TODO: better test
      @database.expects(:save)
      do_update
    end
  end

  describe 'When deleting an entry' do
    def do_delete
      @store.delete_entry('my_collection', 'my_entry')
    end

    setup do
      @store.stubs(:get_entry).returns('entry document')
    end

    it 'gets the entry' do
      @store.expects(:get_entry).with('my_collection', 'my_entry').
        returns('entry document')
      do_delete
    end

    it 'raises EntryNotFound if no entry was found' do
      @store.stubs(:get_entry).returns(nil)
      lambda { do_delete }.should.raise(EntryNotFound)
    end

    it 'deletes the document' do
      @database.expects(:delete).with('entry document')
      do_delete
    end
  end
end
