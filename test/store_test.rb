require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/store'

describe 'Store' do
  setup do
    @database = stub('couchdb database', :view => '', :save => '')
    @store = Store.new(TestDatabase)
    @store.stubs(:database).returns(@database)
  end

  it 'has a  db_name' do
    @store.db_name.should.equal TestDatabase
  end

  describe 'When finding a collection' do
    def do_find
      @store.find_collection('my_collection')
    end

    setup do
      @rows = [{'title' => 'foo', 'subtitle' => 'bar'}]
      @database.stubs(:view).returns('rows' => @rows)
      Hash.any_instance.stubs(:to_atom_feed).returns(Atom::Feed.new)
    end

    it 'finds the collection using the view collection/all' do
      @database.expects(:view).with('collection/all',
        :key => 'my_collection', :count => 1).returns('rows' => @rows)
      do_find
    end

    it 'raises CollectionNotFound if no collection were found' do
      @database.stubs(:view).returns('rows' => [])
      lambda { do_find }.should.raise CollectionNotFound
    end

    it 'coerce the document to an Atom::Feed using #to_atom_feed' do
      @rows.first.expects(:to_atom_feed).returns('an atom feed')
      do_find.should.equal 'an atom feed'
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
