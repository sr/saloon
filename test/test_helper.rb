$: << File.expand_path(File.dirname(__FILE__) + '/../vendor/sinatra/lib')
require 'rubygems'
require 'sinatra'
require 'sinatra/test/spec'
require 'mocha'

TestDatabase = 'saloonrb-test'
