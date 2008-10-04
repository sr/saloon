require 'rubygems'
require 'atom/feed'

class Hash
  def stringify_keys
    inject({}) do |options, (key, value)|
      options[key.to_s] = value
      options
    end
  end

  def to_atom_feed
    hash = self.stringify_keys
    # TODO: support more elements
    %w(title subtitle).inject(Atom::Feed.new) do |feed, element|
      feed.send("#{element}=", hash[element])
      feed
    end
  end
end
