require File.dirname(__FILE__) + '/test_helper'

describe 'Server' do
  setup do
    @server = CouchRest::Server.new('http://localhost:5984')
  end

  it 'has an accessor on its uri' do
    server = CouchRest::Server.new('foo')
    server.uri.to_s.should.equal 'foo'
  end

  specify '#json parse the given json string with the given options' do
    JSON.expects(:parse).with('foo', :bar => :spam)
    @server.send(:json, 'foo', :bar => :spam)
  end

  describe 'HTTP requests utility methods' do
    describe 'GET' do
      it "appends the given path to the server's URI" do
        @server.stubs(:json)
        RestClient.expects(:get).with('http://localhost:5984/foo/bar')
        @server.get('foo/bar')
      end

      it 'appends the given parameters as the query string' do
        @server.stubs(:json)
        RestClient.expects(:get).with('http://localhost:5984/foo?bar=spam')
        @server.get('foo', :bar => 'spam')
      end

      it 'parses the server response as json with :max_nesting set to false' do
        RestClient.stubs(:get).returns('some json')
        @server.expects(:json).with('some json', :max_nesting => false).returns([])
        @server.get('give_me_some_json')
      end

      it 'do not parse the result as json if :no_json is specified' do
        RestClient.stubs(:get)
        @server.expects(:json).never
        @server.get('foo', :no_json => true)
      end
    end

    describe 'POST' do
      setup do
        @server.stubs(:json)
      end

      it "appends the given path to server's URI" do
        RestClient.expects(:post).with('http://localhost:5984/a/b', nil, anything)
        @server.post('a/b')
      end

      it 'appends the given parameters as the query string' do
        RestClient.expects(:post).with('http://localhost:5984/foo?bar=spam', nil, anything)
        @server.post('foo', nil, :bar => 'spam')
      end

      it 'jsonify the given body and post it' do
        body = {:foo => 'bar'}
        body.expects(:to_json).returns('some json')
        RestClient.expects(:post).with(anything, 'some json', anything)
        @server.post('foo', body)
      end

      it 'passes given headers to RestClient' do
        RestClient.expects(:post).with(anything, anything, {'Content-Type' => 'application/json'})
        @server.post('foo', nil, :headers => {'Content-Type' => 'application/json'})
      end
    end

    describe 'PUT' do
      setup do
        @server.stubs(:json)
      end

      it "appends the given path to the server's URI" do
        RestClient.expects(:put).with('http://localhost:5984/a/b', anything)
        @server.put('a/b')
      end

      it 'jsonify and PUT the given body' do
        body = {:foo => 'bar'}
        body.expects(:to_json).returns('some json')
        RestClient.expects(:put).with(anything, 'some json')
        @server.put('foo', body)
      end
    end

    describe 'DELETE' do
      it "appends the given path to the server's URI" do
        @server.stubs(:json).returns('')
        RestClient.expects(:delete).with('http://localhost:5984/a/b')
        @server.delete('a/b')
      end
    end
  end

  describe 'Getting a list of all the databases' do
    it 'GET _all_dbs' do
      @server.expects(:get).with('_all_dbs')
      @server.databases
    end
  end

  describe 'Getting a database' do
    it 'creates a new Database object with the given name and itselfs' do
      CouchRest::Database.expects(:new).with(@server, 'mydb')
      @server.database('mydb')
    end

    it 'returns a Database object' do
      @server.database('mydb').should.be.an.instance_of CouchRest::Database
    end
  end

  describe 'Getting info on the server' do
    it 'GET the server URI' do
      @server.expects(:get).with('/')
      @server.info
    end
  end

  describe 'Restarting the server' do
    it 'POST _restart' do
      @server.expects(:post).with('_restart')
      @server.restart!
    end
  end

  describe 'Creating a new database' do
    it 'PUT to database_name' do
      @server.expects(:put).with('mydb')
      @server.create_db('mydb')
    end

    it 'returns a Database object' do
      @server.stubs(:put)
      @server.create_db('mydb').should.be.an.instance_of CouchRest::Database
    end
  end
end
