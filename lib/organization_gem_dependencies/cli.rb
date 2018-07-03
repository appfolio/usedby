# frozen_string_literal: true

require 'base64'
require 'io/console'
require 'json'
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

      gems = {}
      gemfiles(github) do |gemfile|
        STDERR.puts "Processing #{gemfile.repository.name}/#{gemfile.path}"
        content = nil
        sleep_time = 0
        while content.nil?
          begin
            content = Base64.decode64(github.get(gemfile.url).content)
          rescue StandardError
            sleep_time += 1
            STDERR.puts "Sleeping #{sleep_time} seconds"
            sleep(sleep_time)
          end
        end
        merge!(gems, process_gemfile(
                       Bundler::LockfileParser.new(content),
                       "#{gemfile.repository.name}/#{gemfile.path}"
        ))
      end
      output gems

      0
    end

    private

    def gemfiles(github)
      github.search_code(SEARCH_TERM, per_page: 1000)
      last_response = github.last_response

      matches = last_response.data.items
      until last_response.rels[:next].nil?
        last_response = last_response.rels[:next].get
        matches.concat last_response.data.items
      end

      matches.sort_by(&:html_url).each do |match|
        yield match
      end
    end

    def merge!(base, additions)
      additions.each do |gem, versions|
        if base.include? gem
          base_versions = base[gem]
          versions.each do |version, projects|
            if base_versions.include? version
              base_versions[version].concat(projects)
            else
              base_versions[version] = projects
            end
          end
        else
          base[gem] = versions
        end
      end
    end

    def output(gems)
      sorted_gems = {}
      gems.sort.each do |gem, versions|
        sorted_gems[gem] = {}
        versions.sort.each do |version, projects|
          sorted_gems[gem][version] = projects.sort
        end
      end
      puts JSON.pretty_generate(sorted_gems)
    end

    def parse_options
      @options = { direct: false }
      OptionParser.new do |config|
        config.banner = <<~USAGE
          Usage: organization_gem_dependencies [options]
        USAGE
        config.on('-d', '--direct',
                  'Consider only direct dependencies.') do |direct|
          @options[:direct] = direct
        end
        config.version = OrganizationGemDependencies::VERSION
      end.parse!
    end

    def process_gemfile(gemfile, project)
      dependencies = gemfile.dependencies.map { |dependency, _, _| dependency }
      gems = {}

      gemfile.specs.each do |spec|
        next if @options[:direct] && !dependencies.include?(spec.name)
        gems[spec.name] = {}
        gems[spec.name][spec.version] = [project]
      end
      gems
    end
  end
end
