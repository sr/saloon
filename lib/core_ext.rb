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
    updated
    links).inject(Atom::Entry.new) do |entry, element|
      case element
      when 'links'
        hash['links'].each { |link| entry.links.new(link) }
      else
        entry.send("#{element}=", hash[element])
      end if hash[element]

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
