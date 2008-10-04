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
      @store.stubs(:find_collection).returns(stub('an Atom::Collection'))
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
      @store.expects(:find_collection).with('articles').returns(stub('an Atom::Collection'))
      do_get
    end
  end
end
