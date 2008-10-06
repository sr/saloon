require File.dirname(__FILE__) + '/test_helper'

describe 'Database' do
  before(:each) do
    @server = stub('server', :get => '', :post => '', :put => '', :delete => '')
    @database = CouchRest::Database.new(@server, TestDatabase)
  end

  it 'has an accessor on its name' do
    @database.name.should.equal TestDatabase
  end

  it 'has an accessor on the server instance' do
    @database.server.should.equal @server
  end

  specify '#base64 removes new lines to workaround <https://issues.apache.org/jira/browse/COUCHDB-19>' do
    @database.send(:base64, 'foo').should.equal 'Zm9v'
  end

  describe 'Getting a list of documents' do
    it 'GET $database_name/_all_docs' do
      @server.expects(:get).with(TestDatabase + '/_all_docs', {})
      @database.documents
    end

    it 'uses given parameters' do
      @server.expects(:get).with(TestDatabase + '/_all_docs', :startkey => 'somedoc', :count => 3)
      @database.documents(:startkey => 'somedoc', :count => 3)
    end
  end

  describe 'Creating a temporary view' do
    it 'POST $database_name/_temp_view with the given fonction' do
      @server.expects(:post).with(TestDatabase + '/_temp_view', 'js function', anything)
      @database.temp_view('js function')
    end

    it "set the request's Content-Type to application/json" do
      @server.expects(:post).with(anything, anything,
        has_entries(:headers => {'Content-Type' => 'application/json'}))
      @database.temp_view('foo')
    end

    it 'uses the given parameters' do
      @server.expects(:post).with(anything, 'foo', has_entries(:startkey => 'foo'))
      @database.temp_view('foo', :startkey => 'foo')
    end
  end

  describe 'Getting a view' do
    it 'GET $database_name/_view/$view_name' do
      @server.expects(:get).with("#{TestDatabase}/_view/my-view", {})
      @database.view('my-view')
    end

    it 'uses the given parameters' do
      @server.expects(:get).with(anything, :count => 100)
      @database.view('my-view', :count => 100)
    end
  end

  describe 'Getting a document' do
    it 'GET $database_name/$document_id' do
      @server.expects(:get).with("#{TestDatabase}/foobar")
      @database.get('foobar')
    end

    it 'escapes the given document id' do
      CGI.expects(:escape).with('foobar')
      @database.get('foobar')
    end
  end

  describe 'Fetching an attachment' do
    it 'GET $database_name/$document_id/$attachment_id' do
      @server.expects(:get).with("#{TestDatabase}/my-doc/foo", anything)
      @database.fetch_attachment('my-doc', 'foo')
    end

    it 'escapes the document id and the attachement id' do
      CGI.expects(:escape).with('my-doc')
      CGI.expects(:escape).with('foo')
      @database.fetch_attachment('my-doc', 'foo')
    end
  end

  describe 'Saving a document' do
    # TODO: stringify_keys! to accept symbol keys

    it 'encodes the attachments if the given document contains any' do
      doc = {'_attachments' => 'foo'}
      doc.expects(:[]=).with('_attachments', 'bar')
      @database.expects(:encode_attachments).with(doc['_attachments']).returns('bar')
      @database.save(doc)
    end

    it 'POST the document to $database_name when no document id was specified' do
      doc = {:foo => 'bar'}
      @server.expects(:post).with(TestDatabase, doc)
      @database.save(doc)
    end

    describe 'When a document id was specified' do
      it 'PUT the document to $database_name/$document_id' do
        doc = {'_id' => 'mydocid', 'foo' => 'bar'}
        @server.expects(:put).with("#{TestDatabase}/#{doc['_id']}", doc)
        @database.save(doc)
      end

      it 'escapes the given document id' do
        CGI.expects(:escape).with('mydocid')
        @database.save('_id' => 'mydocid')
      end
    end
  end

  describe 'Bulk saving a bunch of documents' do
    it 'POST the documents to $database_name/_bulk_docs' do
      @server.expects(:post).with("#{TestDatabase}/_bulk_docs", :docs => ['doc1', 'doc2'])
      @database.bulk_save(['doc1', 'doc2'])
    end
  end

  describe 'Deleting a document' do
    describe 'When given the document id' do
      it 'DELETE $database_name/$document_id' do
        @server.expects(:delete).with("#{TestDatabase}/mydocid")
        @database.delete('mydocid')
      end

      it 'escapes the given document id' do
        CGI.expects(:escape).with('mydocid')
        @database.delete('mydocid')
      end
    end

    describe 'When given an Hash representing a document' do
      it 'raises ArgumentError if it do not have an _id key' do
        proc do
          @database.delete('foo' => 'bar')
        end.should.raise(ArgumentError)
      end

      it 'DELETE $database_name/$document_id' do
        @server.expects(:delete).with("#{TestDatabase}/mydocid")
        @database.delete('_id' => 'mydocid')
      end

      it 'DELETE $database_name/$document_id?rev=$revision_id' do
        @server.expects(:delete).with("#{TestDatabase}/mydocid?rev=34")
        @database.delete('_id' => 'mydocid', '_rev' => 34)
      end

      it 'escapes the given document id' do
        CGI.expects(:escape).with('mydocid')
        @database.delete('_id' => 'mydocid')
      end
    end

    it 'raises ArgumentError if the given argument is neither a document id nor a document' do
      proc do
        @database.delete(:fooo)
      end.should.raise(ArgumentError)
    end
  end

  describe 'Deleting the database' do
    it 'DELETE $database_name' do
      @server.expects(:delete).with(TestDatabase)
      @database.delete!
    end
  end
end
