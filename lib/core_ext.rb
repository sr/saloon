require 'rubygems'
require 'atom/feed'
require 'atom/entry'

class Hash
  def stringify_keys
    inject({}) do |options, (key, value)|
      options[key.to_s] = value
      options
    end
  end

  def to_atom_entry
    hash = self.stringify_keys
    %w(title
    summary
    content
    published
    edited
    updated).inject(Atom::Entry.new) do |entry, element|
      entry.send("#{element}=", hash[element]) if hash[element]
      entry
    end
  end

  def to_atom_feed
    hash = self.stringify_keys
    # TODO: support more elements
    %w(base title subtitle).inject(Atom::Feed.new) do |feed, element|
      feed.send("#{element}=", hash[element]) if hash[element]
      feed
    end
  end
end
