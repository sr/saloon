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

    def self.from_doc(doc)
      doc = doc.stringify_keys

      Atom::Entry::Elements.inject(Atom::Entry.new) do |entry, element|
        next(entry) unless doc[element]

        if element == 'links'
          doc['links'].each { |link| entry.links.new(link) }
        else
          entry.send("#{element}=", doc[element])
        end

        entry
      end
    end

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

  class Feed
    Elements = %w(base title subtitle).freeze

    def self.from_doc(doc)
      doc = doc.stringify_keys

      Elements.inject(Atom::Feed.new) do |feed, element|
        feed.send("#{element}=", doc[element]) if doc[element]
        feed
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

  def to_atom_entry
    Atom::Entry.from_doc(self)
  end

  def to_atom_feed
    Atom::Feed.from_doc(self)
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
