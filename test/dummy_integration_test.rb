begin
  service = Atom::Service.new('http://0.0.0.0:1234/')
  collection = service.workspaces.first.collections.first
  collection.feed.update!
  count = collection.feed.entries.length
  entry = Atom::Entry.new(:title => 'foo', :content => 'bar')
  collection.post!(entry)
  collection.feed.update!
  collection.feed.entries.length.should.equal count+1
rescue Errno::ECONNREFUSED
  puts '#  Please run `ruby lib/app.rb -p1234` to run this test.'
end
