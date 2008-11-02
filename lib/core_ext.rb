require 'rubygems'
require 'addressable/uri'
require 'atom/feed'
require 'atom/entry'

module Atom
  class Link
    def ==(link)
      self['extensions'] == link['extensions'] &&
        self['href']     == link['href'] &&
        self['rel']      == link['rel']
    end

    def to_doc
      { :rel => self['rel'], :href => self['href'] }
    end
  end

  class Entry
    Elements = %w(title id summary content published edited updated links).freeze

    def to_doc
      Elements.inject({}) do |doc, element|
        if element == 'links'
          doc['links'] = links.map(&:to_doc)
        elsif value = self.send(element)
          doc[element] = value.to_s
        end

        doc
      end
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

  def to_atom_feed
    hash = stringify_keys

    FeedElements.inject(Atom::Feed.new) do |feed, element|
      feed.send("#{element}=", hash[element]) if hash[element]
      feed
    end
  end

  def to_atom_entry
    hash = stringify_keys

    Atom::Entry::Elements.inject(Atom::Entry.new) do |entry, element|
      next(entry) unless hash[element]

      if element == 'links'
        hash['links'].each { |link| entry.links.new(link) }
      else
        entry.send("#{element}=", hash[element])
      end

      entry
    end
  end
end

class String
  def to_uri
    Addressable::URI.parse(self)
  end
end

# otherwise, atom-tools blows up
class Addressable::URI
  def to_uri
    self
  end
end
