require 'rubygems'
require 'sinatra'

require File.dirname(__FILE__) + '/store'

mime :atom,     'application/atom+xml'
mime :atomsvc,  'application/atomsvc+xml'

configure do
  DatabaseName = 'saloonrb'
end

helpers do
  def store
    @store ||= Store.new(DatabaseName)
  end
end

get '/' do
  content_type :atomsvc
end

get '/:collection' do
  content_type :atom
  store.find_collection(params[:collection]).to_s
end
