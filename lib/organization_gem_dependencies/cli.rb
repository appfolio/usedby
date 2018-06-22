# frozen_string_literal: true

require 'optparse'

module OrganizationGemDependencies
  # Define the command line interface.
  class Cli
    def run
      parse_options
      0
    end

    private

    def parse_options
      @options = {}
      OptionParser.new do |config|
        config.banner = <<~USAGE
          Usage: organization_gem_dependencies [options]
        USAGE
        config.version = OrganizationGemDependencies::VERSION
      end.parse!
    end
  end
end
