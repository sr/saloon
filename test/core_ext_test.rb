require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/core_ext'

describe 'Atom::Entry#from_doc' do
  setup do
    @doc = { :title => 'Atom-Powered Robots Run Amok',
      :id         => 'http://foo.org/bar',
      :summary    => 'Some text.',
      :content    => 'Even more text...',
      :published  => Time.now,
      :updated    => Time.now,
      :edited     => Time.now,
      :links      => [
        { :rel => 'self',
          :href => 'http://foo.org/bar/spam.atom' },
        { :rel => 'edit',
          :href => 'http://foo.org/edit/bar' }
      ]
    }
  end

  it 'returns an Atom::Entry' do
    Atom::Entry.from_doc(@doc).should.be.an.instance_of Atom::Entry
  end

  %w(id
  title
  summary
  content
  published
  edited
  updated).map(&:to_sym).each do |element|
    it "imports '#{element}' element" do
      Atom::Entry.from_doc(@doc).send(element).to_s.should.equal @doc[element].to_s
    end
  end

  it 'imports links' do
    Atom::Entry.from_doc(@doc).links.first.should.
      equal Atom::Link.new(:rel => 'self', :href => 'http://foo.org/bar/spam.atom')
    Atom::Entry.from_doc(@doc).links.last.should.
      equal Atom::Link.new(:rel => 'edit', :href => 'http://foo.org/edit/bar')
  end
end

describe 'Atom::Entry#to_doc' do
  setup do
    @entry = Atom::Entry.new(:title => 'foo', :summary => 'bar', :content => 'spam',
      :id => 'http://foo.org/my_entry')
    @entry.updated! && @entry.edited! && @entry.published!
    @entry.edit_url = 'http://example.org/edit/foo'
    @entry.links.new(:rel => 'self', :href => 'http://example.org')
  end

  %w(id
  title
  summary
  content
  published
  edited
  updated).each do |element|
    it "imports '#{element}' element" do
      @entry.to_doc[element].to_s.should.equal @entry.send(element).to_s
    end

    it 'imports links' do
      Atom::Link.new(@entry.to_doc['links'].first).should.equal @entry.links.first
      Atom::Link.new(@entry.to_doc['links'].last).should.equal @entry.links.last
    end
  end
end

describe 'Hash#to_atom_entry' do
  it 'is an handy helper for Atom::Entry.from_doc' do
    Atom::Entry.expects(:from_doc).with(:foo => 'bar').returns(Atom::Entry.new)
    {:foo => 'bar'}.to_atom_entry.should.be.an.instance_of(Atom::Entry)
  end
end

describe 'Atom::Feed#from_doc' do
  setup do
    @doc = { :title => 'My AtomPub Feed',
      :subtitle => 'Has a Subtitle!',
      :base     => 'http://0.0.0.0:1234/' }
  end

  it 'returns an Atom::Feed' do
    Atom::Feed.from_doc(@doc).should.be.an.instance_of Atom::Feed
  end

  %w(base title subtitle).map(&:to_sym).each do |element|
    it "converts #{element}" do
      Atom::Feed.from_doc(@doc).send(element).to_s.should.equal @doc[element]
    end
  end
end

describe 'Hash#to_atom_feed' do
  it 'is an handy helper for Atom::Feed.from_doc' do
    Atom::Entry.expects(:from_doc).with(:foo => 'bar').returns(Atom::Entry.new)
    {:foo => 'bar'}.to_atom_entry.should.be.an.instance_of(Atom::Entry)
  end
end

describe 'String#to_uri' do
  it 'parses itselfs into an Addressable::URI' do
    'http://foo.org'.to_uri.should.equal Addressable::URI.parse('http://foo.org')
  end
end
