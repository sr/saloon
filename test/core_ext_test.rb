require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/core_ext'

describe 'Hash#to_atom_entry' do
  setup do
    @hash = { :title => 'Atom-Powered Robots Run Amok',
      :summary    => 'Some text.',
      :content    => 'Even more text...',
      :published  => Time.now,
      :updated    => Time.now,
      :edited     => Time.now
    }
  end

  it 'returns an Atom::Entry' do
    @hash.to_atom_entry.should.be.an.instance_of Atom::Entry
  end

  %w(title summary content published edited updated).map(&:to_sym).each do |element|
    it "converts #{element}" do
      @hash.to_atom_entry.send(element).to_s.should.equal @hash[element].to_s
    end
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
