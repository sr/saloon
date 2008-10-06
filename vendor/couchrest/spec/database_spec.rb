require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/couch_rest'

describe CouchRest::Database do
  before(:each) do
    @couch_rest = CouchRest.new(CouchHost)
    @database = @couch_rest.database(TestDatabase).delete! rescue nil
    @database = @couch_rest.create_db(TestDatabase)
  end
    
  describe "map query with _temp_view in Javascript" do
    before(:each) do
      @database.bulk_save([
          {"wild" => "and random"},
          {"mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      @temp_view = {:map => "function(doc){for(var w in doc){ if(!w.match(/^_/))emit(w,doc[w])}}"}
    end

    it "should return the result of the temporary function" do
      rs = @database.temp_view(@temp_view)
      rs['rows'].select{|r|r['key'] == 'wild' && r['value'] == 'and random'}.length.should == 1
    end

    it "should work with a range" do
      rs = @database.temp_view(@temp_view,{:startkey => "b", :endkey => "z"})
      rs['rows'].length.should == 2
    end

    it "should work with a key" do
      rs = @database.temp_view(@temp_view,{:key => "wild"})
      rs['rows'].length.should == 1
    end

    it "should work with a count" do
      rs = @database.temp_view(@temp_view,{:count => 1})
      rs['rows'].length.should == 1
    end
  end

  describe "map/reduce query with _temp_view in Javascript" do
    before(:each) do
      @database.bulk_save([
          {"beverage" => "beer", :count => 4},
          {"beverage" => "beer", :count => 2},
          {"beverage" => "tea", :count => 3}
        ])
    end
    it "should return the result of the temporary function" do
      rs = @database.temp_view(:map => "function(doc){emit(doc.beverage, doc.count)}", :reduce =>  "function(beverage,counts){return sum(counts)}")
      # rs.should == 'x'
      rs['rows'][0]['value'].should == 9
    end
  end
  
  describe "saving a view" do
    before(:each) do
      @view = {'test' => {'map' => 'function(doc) {
        if (doc.word && !/\W/.test(doc.word)) {
          emit(doc.word,null);
        }
      }'}}
      @database.save({
        "_id" => "_design/test",
        :views => @view
      })
    end
    it "should work properly" do
      @database.bulk_save([
        {"word" => "once"},
        {"word" => "and again"}
      ])
      @database.view('test/test')['total_rows'].should == 1
    end
    it "should round trip" do
      @database.get("_design/test")['views'].should == @view
    end
  end

  describe "select from an existing view" do
    before(:each) do
      r = @database.save({
        "_id" => "_design/first", 
        :views => {
          :test => {
            :map => <<-eoj
              function(doc) {
                for(var w in doc) {
                  if(!w.match(/^_/))
                    emit(w,doc[w])
                } 
              }
            eoj
            }
          }
        })
      @database.bulk_save([
          {"wild" => "and random"},
          {"mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
    end
    it "should have the view" do
      @database.get('_design/first')['views']['test']['map'].should include("for(var w in doc)")
    end
    it "should list from the view" do
      rs = @database.view('first/test')
      rs['rows'].select{|r|r['key'] == 'wild' && r['value'] == 'and random'}.length.should == 1
    end
    it "should work with a range" do
      rs = @database.view('first/test',{:startkey => "b", :endkey => "z"})
      rs['rows'].length.should == 2
    end
    it "should work with a key" do
      rs = @database.view('first/test',{:key => "wild"})
      rs['rows'].length.should == 1
    end
    it "should work with a count" do
      rs = @database.view('first/test',{:count => 1})
      rs['rows'].length.should == 1
    end
  end

  describe "GET (document by id) when the doc exists" do
    before(:each) do
      @r = @database.save({'lemons' => 'from texas', 'and' => 'spain'})
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @database.save({'_id' => @docid, 'will-exist' => 'here'})
    end
    it "should get the document" do
      doc = @database.get(@r['id'])
      doc['lemons'].should == 'from texas'
    end
    it "should work with a funky id" do
      @database.get(@docid)['will-exist'].should == 'here'
    end
  end

  describe "POST (adding bulk documents)" do
    it "should add them without ids" do
      rs = @database.bulk_save([
          {"wild" => "and random"},
          {"mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      rs['new_revs'].each do |r|
        @database.get(r['id'])
      end
    end
    it "should add them with uniq ids" do
      rs = @database.bulk_save([
          {"_id" => "oneB", "wild" => "and random"},
          {"_id" => "twoB", "mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      rs['new_revs'].each do |r|
        @database.get(r['id'])
      end
    end
    it "in the case of an id conflict should not insert anything" do
      @r = @database.save({'lemons' => 'from texas', 'and' => 'how', "_id" => "oneB"})
      
      lambda do
      rs = @database.bulk_save([
          {"_id" => "oneB", "wild" => "and random"},
          {"_id" => "twoB", "mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      end.should raise_error(RestClient::RequestFailed)
    
      lambda do
        @database.get('twoB')        
      end.should raise_error(RestClient::ResourceNotFound)
    end
  end

  describe "POST (new document without an id)" do
    it "should start empty" do
      @database.documents["total_rows"].should == 0
    end
    it "should create the document and return the id" do
      r = @database.save({'lemons' => 'from texas', 'and' => 'spain'})
      r2 = @database.get(r['id'])
      r2["lemons"].should == "from texas"
    end
  end

  describe "PUT document with attachment" do
    before(:each) do
      @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
      @doc = {
        "_id" => "mydocwithattachment",
        "field" => ["some value"],
        "_attachments" => {
          "test.html" => {
            "type" => "text/html",
            "data" => @attach
          }
        }
      }
      @database.save(@doc)
    end
    it "should save and be indicated" do
      doc = @database.get("mydocwithattachment")
      doc['_attachments']['test.html']['length'].should == @attach.length
    end
    it "should be there" do
      attachment = @database.fetch_attachment("mydocwithattachment","test.html")
      attachment.should == @attach
    end
  end
  
  describe "PUT document with attachment stub" do
    before(:each) do
      @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
      doc = {
        '_id' => 'mydocwithattachment',
        'field' => ['some_value'],
        '_attachments' => {
          'test.html' => {
            'type' => 'text/html', 'data' => @attach
          }
        }
      }
      @database.save(doc)
      doc = @database.get('mydocwithattachment')
      doc['field'] << 'another value'
      @database.save(doc)
    end
    
    it 'should be there' do
      attachment = @database.fetch_attachment('mydocwithattachment', 'test.html')
      attachment.should == @attach
    end
  end


  describe "PUT document with multiple attachments" do
    before(:each) do
      @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
      @attach2 = "<html><head><title>Other Doc</title></head><body><p>Has more words.</p></body></html>"
      @doc = {
        "_id" => "mydocwithattachment",
        "field" => ["some value"],
        "_attachments" => {
          "test.html" => {
            "type" => "text/html",
            "data" => @attach
          },
          "other.html" => {
            "type" => "text/html",
            "data" => @attach2
          }
        }
      }
      @database.save(@doc)
    end
    it "should save and be indicated" do
      doc = @database.get("mydocwithattachment")
      doc['_attachments']['test.html']['length'].should == @attach.length
      doc['_attachments']['other.html']['length'].should == @attach2.length
    end
    it "should be there" do
      attachment = @database.fetch_attachment("mydocwithattachment","test.html")
      attachment.should == @attach
    end
    it "should be there" do
      attachment = @database.fetch_attachment("mydocwithattachment","other.html")
      attachment.should == @attach2
    end
  end


  describe "POST document with attachment (with funky name)" do
    before(:each) do
      @attach = "<html><head><title>My Funky Doc</title></head><body><p>Has words.</p></body></html>"
      @doc = {
        "field" => ["some other value"],
        "_attachments" => {
          "http://example.com/stuff.cgi?things=and%20stuff" => {
            "type" => "text/html",
            "data" => @attach
          }
        }
      }
      @docid = @database.save(@doc)['id']
    end
    it "should save and be indicated" do
      doc = @database.get(@docid)
      doc['_attachments']['http://example.com/stuff.cgi?things=and%20stuff']['length'].should == @attach.length
    end
    it "should be there" do
      attachment = @database.fetch_attachment(@docid,"http://example.com/stuff.cgi?things=and%20stuff")
      attachment.should == @attach
    end
  end

  describe "PUT (new document with url id)" do
    it "should create the document" do
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @database.save({'_id' => @docid, 'will-exist' => 'here'})
      lambda{@database.save({'_id' => @docid})}.should raise_error(RestClient::Request::RequestFailed)
      @database.get(@docid)['will-exist'].should == 'here'
    end
  end
  

  describe "PUT (new document with id)" do
    it "should start without the document" do
      # r = @database.save({'lemons' => 'from texas', 'and' => 'spain'})
      @database.documents['rows'].each do |doc|
        doc['id'].should_not == 'my-doc'
      end
      # should_not include({'_id' => 'my-doc'})
      # this needs to be a loop over docs on content with the post
      # or instead make it return something with a fancy <=> method
    end
    it "should create the document" do
      @database.save({'_id' => 'my-doc', 'will-exist' => 'here'})
      lambda{@database.save({'_id' => 'my-doc'})}.should raise_error(RestClient::Request::RequestFailed)
    end
  end
  
  describe "PUT (existing document with rev)" do
    before(:each) do
      @database.save({'_id' => 'my-doc', 'will-exist' => 'here'})
      @doc = @database.get('my-doc')
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @database.save({'_id' => @docid, 'now' => 'save'})
    end
    it "should start with the document" do
      @doc['will-exist'].should == 'here'
      @database.get(@docid)['now'].should == 'save'
    end
    it "should save with url id" do
      doc = @database.get(@docid)
      doc['yaml'] = ['json', 'word.']
      @database.save doc
      @database.get(@docid)['yaml'].should == ['json', 'word.']
    end
    it "should fail to resave without the rev" do
      @doc['them-keys'] = 'huge'
      @doc['_rev'] = 'wrong'
      # @database.save(@doc)
      lambda {@database.save(@doc)}.should raise_error
    end
    it "should update the document" do
      @doc['them-keys'] = 'huge'
      @database.save(@doc)
      now = @database.get('my-doc')
      now['them-keys'].should == 'huge'
    end
  end
  
  describe "DELETE existing document" do
    before(:each) do
      @r = @database.save({'lemons' => 'from texas', 'and' => 'spain'})
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @database.save({'_id' => @docid, 'will-exist' => 'here'})
    end
    it "should work" do
      doc = @database.get(@r['id'])
      doc['and'].should == 'spain'
      @database.delete doc
      lambda{@database.get @r['id']}.should raise_error
    end
    it "should work with uri id" do
      doc = @database.get(@docid)
      @database.delete doc
      lambda{@database.get @docid}.should raise_error
    end
  end
  
  it "should list documents" do
    5.times do
      @database.save({'another' => 'doc', 'will-exist' => 'anywhere'})
    end
    ds = @database.documents
    ds['rows'].should be_an_instance_of(Array)
    ds['rows'][0]['id'].should_not be_nil
    ds['total_rows'].should == 5
  end
  
  it "should list documents with keys and such" do
    9.times do |i|
      @database.save({'_id' => "doc#{i}",'another' => 'doc', 'will-exist' => 'here'})
    end
    ds = @database.documents
    ds['rows'].should be_an_instance_of(Array)
    ds['rows'][0]['id'].should == "doc0"
    ds['total_rows'].should == 9
    ds = @database.documents(:startkey => 'doc0', :endkey => 'doc3')
    ds['rows'].length.should == 4
    ds = @database.documents(:key => 'doc0')
    ds['rows'].length.should == 1
  end
  
  describe "deleting a database" do
    it "should start with the test database" do
      @couch_rest.databases.should include('couchrest-test')
    end
    it "should delete the database" do
      db = @couch_rest.database('couchrest-test')
      # r = 
      db.delete!
      # r['ok'].should == true
      @couch_rest.databases.should_not include('couchrest-test')
    end
  end
end
