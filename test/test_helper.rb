require 'rubygems'
require 'sinatra'
require 'sinatra/test/spec'
require 'mocha'

TestDatabase = 'saloonrb-test' unless defined?(TestDatabase)

Sinatra::Application.default_options.merge!(:raise_errors => false)
