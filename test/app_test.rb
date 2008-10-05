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

    it 'is successful' do
      do_get
      should.be.ok
    end

    it 'is application/atomsvc+xml' do
      do_get
      headers['Content-Type'].should.equal 'application/atomsvc+xml'
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
  end
end
