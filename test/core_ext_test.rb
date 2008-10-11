require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/core_ext'

describe 'Hash with mixin HashToAtomEntry' do
  setup do
    @hash = { :title => 'Atom-Powered Robots Run Amok',
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
    @hash.to_atom_entry.should.be.an.instance_of Atom::Entry
  end

  %w(title
  summary
  content
  published
  edited
  updated).map(&:to_sym).each do |element|
    it "imports '#{element}' element" do
      @hash.to_atom_entry.send(element).to_s.should.equal @hash[element].to_s
    end
  end

  it 'imports links' do
    @hash.to_atom_entry.links.first.should.
      equal Atom::Link.new(:rel => 'self', :href => 'http://foo.org/bar/spam.atom')
    @hash.to_atom_entry.links.first.should.
      equal Atom::Link.new(:rel => 'self', :href => 'http://foo.org/bar/spam.atom')
  end
end

describe 'Hash#to_atom_feed' do
  setup do
    @hash = { :title => 'My AtomPub Feed',
      :subtitle => 'Has a Subtitle!',
      :base     => 'http://0.0.0.0:1234/' }
  end

  it 'returns an Atom::Feed' do
    @hash.to_atom_feed.should.be.an.instance_of Atom::Feed
  end

  %w(base title subtitle).map(&:to_sym).each do |element|
    it "converts #{element}" do
      @hash.to_atom_feed.send(element).to_s.should.equal @hash[element]
    end
  end
end

describe 'Atom::Entry#to_h' do
  setup do
    @entry = Atom::Entry.new(:title => 'foo', :summary => 'bar', :content => 'spam')
    @entry.updated! && @entry.edited! && @entry.published!
    @entry.edit_url = 'http://example.org/edit/foo'
    @entry.links.new(:rel => 'self', :href => 'http://example.org')
  end

  %w(title
  summary
  content
  published
  edited
  updated).each do |element|
    it "imports '#{element}' element" do
      @entry.to_h[element].to_s.should.equal @entry.send(element).to_s
    end

    it 'imports links' do
      Atom::Link.new(@entry.to_h['links'].first).should.equal @entry.links.first
      Atom::Link.new(@entry.to_h['links'].last).should.equal @entry.links.last
    end
  end
end
