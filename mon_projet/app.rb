require 'bundler'
Bundler.require
#$:.unshift File.expand_path("./../lib", __FILE__)
require_relative 'lib/app/scrapper'
#require 'scrapper'
my_class = Scrapper.new
my_class.perform