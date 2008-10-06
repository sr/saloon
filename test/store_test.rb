require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/store'

describe 'Store' do
  setup do
    @database = stub('couchdb database', :view => '', :save => '')
    @store = Store.new(TestDatabase)
    @store.stubs(:database).returns(@database)
    @rows = [
      { 'id' => 'my_collection',
        'key' => ['my_collection', 0],
        'value' => {'_id' => 'my_collection', 'type' => 'collection', 'title' => 'My AtomPub Collection'}},
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
      Store.class_eval { public :atom_collection_from, :atom_entries_from }
      @store = Store.new(TestDatabase)
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

    it 'raises CollectionNotFound if no collection were found' do
      @store.stubs(:atom_collection_from).returns(nil)
      lambda { do_find }.should.raise CollectionNotFound
    end

    it 'returns an Atom::Feed with the entries' do
      do_find.should.be.an.instance_of(Atom::Feed)
      do_find.entries.length.should.equal 2
      do_find.entries.first.title.to_s.should.equal 'Entry 1'
      do_find.entries.last.title.to_s.should.equal 'Entry 2'
    end
  end

  describe 'When finding an entry' do
    def do_find
      @store.find_entry('my_collection', 'my_entry')
    end

    setup do
      @rows = [{'title' => 'foo', 'content' => 'bar'}]
      @database.stubs(:view).returns('rows' => @rows)
      Hash.any_instance.stubs(:to_atom_entry).returns(Atom::Entry.new)
    end

    it 'finds the entry using the view entry/by_collection' do
      @database.expects(:view).with('entry/by_collection',
        :key => ['my_collection', 'my_entry'], :count => 1).
        returns('rows' => @rows)
      do_find
    end

    it 'raises EntryNotFound if no entry were found in the given collection' do
      @database.stubs(:view).returns('rows' => [])
      lambda { do_find }.should.raise EntryNotFound
    end

    it 'coerce the document to an Atom::Entry using #to_atom_entry' do
      @rows.first.expects(:to_atom_entry).returns('an atom entry')
      do_find.should.equal 'an atom entry'
    end
  end

  describe 'When creating an entry' do
    def do_create
      @store.create_entry('my_collection', @entry.to_s)
    end

    setup do
      @store.stubs(:find_collection)
      @hash = {:title => 'foo', :content => 'bar'}
      @entry = Atom::Entry.new(@hash)
      @entry.stubs(:to_h).returns(@hash)
      Atom::Entry.stubs(:parse).returns(@entry)
    end

    it 'finds the collection' do
      @store.expects(:find_collection).with('my_collection')
      do_create
    end

    it 'parses the entry' do
      Atom::Entry.expects(:parse).with(@entry.to_s).returns(@entry)
      do_create
    end

    it 'coerces the parsed entry to an hash' do
      @entry.expects(:to_h).returns(@hash)
      do_create
    end

    it 'saves the hash to the database' do
      @database.expects(:save).with(@hash)
      do_create
    end

    it 'sets the type of the document to "entry"' do
      do_create
      @hash[:type].should.equal 'entry'
    end

    it 'sets the collection to which the entry belongs' do
      do_create
      @hash[:collection].should.equal 'my_collection'
    end
  end
end
