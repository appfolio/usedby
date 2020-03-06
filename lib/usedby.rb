# frozen_string_literal: true

# set environment variable to avoid GemfileNotFound error
ENV['BUNDLE_GEMFILE'] = File.join(__dir__, 'usedby', 'gems.rb') # new name for a Gemfile
require 'usedby/cli'
require 'usedby/version'
