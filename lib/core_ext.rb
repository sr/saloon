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
  end

  class Entry
    Elements = %w(title summary content published edited updated links).freeze

    def to_h
      Elements.inject({}) do |hash, element|
        case element
        when 'links'
          hash['links'] = links.inject([]) do |links, link|
            # TODO: Atom::Link#to_h instead
            links << {:rel => link['rel'], :href => link['href']}
            links
          end
        else
          if value = self.send(element)
            hash[element] = value.to_s
          end
        end
        hash
      end
    end
  end
end

class String
  def to_uri
    Addressable::URI.parse(self)
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
