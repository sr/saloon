require 'rubygems'
require 'sinatra'

require File.dirname(__FILE__) + '/store'

mime :atom_service,   'application/atomsvc+xml'
mime :atom_feed,      'application/atom+xml'
mime :atom_entry,     'application/atom+xml;type=entry'

configure do
  DatabaseName = 'saloonrb'
end

helpers do
  def store
    @store ||= Store.new(DatabaseName)
  end
end

get '/' do
  content_type :atom_service
end

get '/:collection' do
  content_type :atom_feed
  store.find_collection(params[:collection]).to_s
end

get '/:collection/:entry' do
  content_type :atom_entry
  store.find_entry(params[:collection], params[:entry]).to_s
end
