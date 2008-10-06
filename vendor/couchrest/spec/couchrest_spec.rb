require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/couch_rest'

describe CouchRest do
  before(:each) do
    @couch_rest = CouchRest.new(CouchHost)
    @database = @couch_rest.database(TestDatabase)
  end

  after(:each) do
    begin
      @database.delete!
    rescue RestClient::ResourceNotFound
      nil
    end
  end

  describe 'Getting info' do
    it 'list databases' do
      @couch_rest.databases.should be_an_instance_of(Array)
    end

    it 'should get info' do
      @couch_rest.info.should have_key('couchdb')
      @couch_rest.info.should have_key('version')
    end
  end

  it 'should restart' do
    @couch_rest.restart!
  end

  describe 'initializing a database' do
    it 'should return a database' do
      db = @couch_rest.database(TestDatabase)
      db.should be_an_instance_of(CouchRest::Database)
    end
  end

  describe 'successfully creating a database' do
    it 'should start without a database' do
      @couch_rest.databases.should_not include(TestDatabase)
    end

    it 'should return the created database' do
      db = @couch_rest.create_db(TestDatabase)
      db.should be_an_instance_of(CouchRest::Database)
    end

    it 'should create the database' do
      db = @couch_rest.create_db(TestDatabase)
      @couch_rest.databases.should include(TestDatabase)
    end
  end

  describe 'failing to create a database because the name is taken' do
    before(:each) do
      @couch_rest.create_db(TestDatabase)
    end

    it 'should start with the test database' do
      @couch_rest.databases.should include(TestDatabase)
    end

    it 'should PUT the database and raise an error' do
      lambda do
        @couch_rest.create_db(TestDatabase)
      end.should raise_error(RestClient::Request::RequestFailed)
    end
  end
end
