#!/usr/bin/env ruby

$: << "#{File.expand_path(File.dirname(__FILE__))}/../lib"

require 'machine'
require 'user'
require 'system'

$: << '.'

require ARGV[0]