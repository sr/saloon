describe 'CouchRest#new' do
  it 'creates a new Server with the given server URI' do
    CouchRest::Server.expects(:new).with('uri')
    CouchRest.new('uri')
  end

  specify 'uri default to http://localhost:5984/' do
    server = CouchRest.new
    server.uri.to_s.should.equal 'http://localhost:5984/'
  end
end
