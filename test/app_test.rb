require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/app'

describe 'App' do
  setup do
    @store = mock('store')
    Store.stubs(:new).returns(@store)
  end

  describe 'GET /' do
    def do_get
      get_it '/'
    end

    setup do
      @service = stub('an Atom::Service', :to_s => 'xml')
      @store.stubs(:service).returns(@service)
    end

    it 'is successful' do
      do_get
      should.be.ok
    end

    it 'is application/atomsvc+xml' do
      do_get
      headers['Content-Type'].should.equal 'application/atomsvc+xml'
    end

    it 'gets the service document' do
      @store.expects(:service).returns(@service)
      do_get
    end

    it 'returns the atom representation of the service document' do
      @service.expects(:to_s).returns('some xml representing the service doc')
      do_get
      body.should.equal 'some xml representing the service doc'
    end
  end

  describe 'GET /:collection' do
    def do_get
      get_it '/articles'
    end

    setup do
      @collection = stub('an Atom::Collection', :to_s => 'collection')
      @store.stubs(:find_collection).returns(@collection)
    end

    it 'is successful' do
      do_get
      should.be.ok
    end

    it 'is application/atom+xml' do
      do_get
      headers['Content-Type'].should.equal 'application/atom+xml'
    end

    it 'finds the given collection' do
      @store.expects(:find_collection).with('articles').returns(@collection)
      do_get
    end

    it 'returns the atom representation of the collection' do
      do_get
      body.should.equal @collection.to_s
    end

    describe 'When the collection is not found' do
      setup do
        @store.stubs(:find_collection).raises(CollectionNotFound)
      end

      it 'is not found' do
        get_it '/articles'
        should.be.not_found
      end
    end
  end

  describe 'POST /:collection' do
    def do_post
      post_it '/articles', @entry.to_s, :content_type => 'application/atom+xml;type=entry'
    end

    setup do
      @entry = Atom::Entry.new(:title => 'foo', :content => 'bar',
        :edit_url => 'http://example.org/my_collection/my_entry')
      @store.stubs(:create_entry).returns(@entry)
    end

    it 'is created' do
      do_post
      status.should.equal 201
    end

    it 'creates the entry' do
      @store.expects(:create_entry).with('articles', @entry.to_s)
      do_post
    end

    it "sets the Location header to the entry's edit url" do
      do_post
      headers['Location'].should.equal 'http://example.org/my_collection/my_entry'
    end

    it 'returns the atom entry' do
      do_post
      body.should.equal @entry.to_s
    end

    describe 'When the collection is not found' do
      setup do
        @store.stubs(:create_entry).raises(CollectionNotFound)
      end

      it 'is not found' do
        post_it '/articles', @entry.to_s, :content_type => 'application/atom+xml;type=entry'
        should.be.not_found
      end
    end
  end

  describe 'GET /:collection/:entry' do
    def do_get
      get_it '/articles/my_entry'
    end

    setup do
      @entry = stub('an Atom::Entry', :to_s => 'hi, i am an atom entry')
      @store.stubs(:find_entry).returns(@entry)
    end

    it 'is successful' do
      do_get
      should.be.ok
    end

    it 'is application/atom+xml;type=entry' do
      do_get
      headers['Content-Type'].should.equal 'application/atom+xml;type=entry'
    end

    it 'finds the entry in the given collection' do
      @store.expects(:find_entry).with('articles', 'my_entry')
      do_get
    end

    it 'returns the atom representation of the entry' do
      do_get
      body.should.equal @entry.to_s
    end

    describe 'When the entry is not found' do
      setup do
        @store.stubs(:find_entry).raises(EntryNotFound)
      end

      it 'is not found' do
        get_it '/articles/my_entry'
        should.be.not_found
      end
    end
  end

  describe 'PUT /:collection/:entry' do
    def do_put
      put_it '/articles/my_entry', @entry.to_s, :content_type => 'application/atom+xml;type=entry'
    end

    setup do
      @entry = stub('an Atom::Entry', :to_s => 'hi i am an atom entry')
      @store.stubs(:update_entry).returns(@entry)
    end

    it 'is successful' do
      do_put
      should.be.ok
    end

    it 'is application/atom+xml;type=entry' do
      do_put
      headers['Content-Type'].should.equal 'application/atom+xml;type=entry'
    end

    it 'updates the entry' do
      @store.expects(:update_entry).with('articles', 'my_entry', @entry.to_s)
      do_put
    end

    it 'is not found if the collection do not exists' do
      @store.stubs(:update_entry).raises(CollectionNotFound)
      do_put
      should.be.not_found
    end

    it 'is not found if the entry do not exists' do
      @store.stubs(:update_entry).raises(EntryNotFound)
      do_put
      should.be.not_found
    end
  end

  describe 'DELETE /:collection/:entry' do
    def do_delete
      delete_it '/articles/my_entry'
    end

    it 'is success' do
      @store.stubs(:delete_entry)
      do_delete
      should.be.ok
    end

    it 'deletes the entry' do
      @store.expects(:delete_entry).with('articles', 'my_entry')
      do_delete
    end

    it 'is not found if the entry do not exists' do
      @store.stubs(:delete_entry).raises(EntryNotFound)
      do_delete
      should.be.not_found
    end
  end
end
