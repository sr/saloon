require 'rubygems'
require 'atom/feed'
require 'atom/entry'

module Atom
  class Link
    def ==(link)
      self['extensions'] == link['extensions'] &&
        self['href']     == link['href'] &&
        self['rel']      == link['rel']
    end
  end
end

class Hash
  def stringify_keys
    inject({}) do |hash, (key, value)|
      hash[key.to_s] = value
      hash
    end
  end

  FeedElements = %w(base title subtitle).freeze
  EntryElements = %w(title summary content published edited updated links).freeze

  def to_atom_feed
    hash = stringify_keys

    FeedElements.inject(Atom::Feed.new) do |feed, element|
      feed.send("#{element}=", hash[element]) if hash[element]
      feed
    end
  end

  def to_atom_entry
    hash = stringify_keys

    EntryElements.inject(Atom::Entry.new) do |entry, element|
      case element
      when 'links'
        hash['links'].each { |link| entry.links.new(link) }
      else
        entry.send("#{element}=", hash[element])
      end if hash[element]

      entry
    end
  end
end
