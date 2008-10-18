collection = Atom::Collection.new('http://0.0.0.0:1234/my_collection_0')
collection.feed.update!
count = collection.feed.entries.length
entry = Atom::Entry.new(:title => 'foo', :content => 'bar')
collection.post!(entry)
collection.feed.update!
raise unless collection.feed.entries.length == count+1