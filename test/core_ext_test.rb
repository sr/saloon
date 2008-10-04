require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/core_ext'

describe 'Hash#to_atom_feed' do
  it 'returns an Atom::Feed' do
    {}.to_atom_feed.should.be.an.instance_of Atom::Feed
  end

  it 'converts `title`' do
    h = {:title => 'foobar'}
    h.to_atom_feed.title.to_s.should.equal 'foobar'
  end

  it 'converts `subtitle`' do
    h = {:subtitle => 'run amok'}
    h.to_atom_feed.subtitle.to_s.should.equal 'run amok'
  end
end
 
