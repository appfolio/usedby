# frozen_string_literal: true

require 'base64'
require 'io/console'
require 'optparse'

require 'octokit'

module OrganizationGemDependencies
  # Define the command line interface.
  class Cli

    SEARCH_TERM = 'org:appfolio filename:Gemfile.lock'

    def run
      parse_options

      access_token = ENV['GITHUB_ACCESS_TOKEN'] || \
                     STDIN.getpass('GitHub Personal Access Token: ')
      github = Octokit::Client.new(access_token: access_token)

      github.search_code(SEARCH_TERM, per_page: 1000)
      last_response = github.last_response

      matches = last_response.data.items
      until last_response.rels[:next].nil?
        last_response = last_response.rels[:next].get
        matches.concat last_response.data.items
      end

      matches.sort! { |a, b| a.html_url <=> b.html_url }

      matches.each do |match|
        puts "#{match.repository.name}/#{match.path}"
        #puts Base64.decode64(github.get(match.url).content).size
      end

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
