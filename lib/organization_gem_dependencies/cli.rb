# frozen_string_literal: true

require 'base64'
require 'io/console'
require 'json'
require 'optparse'

require 'octokit'

module OrganizationGemDependencies
  # Define the command line interface.
  class Cli
    SEARCH_TERM = 'org:%s filename:Gemfile.lock'
    USAGE = <<~USAGE
      Usage: organization_gem_dependencies [options] GITHUB_ORGANIZATION
    USAGE

    def run
      parse_options
      if ARGV.size != 1
        STDERR.puts USAGE
        return 1
      end
      github_organization = ARGV[0]

      access_token = ENV['GITHUB_ACCESS_TOKEN'] || \
                     STDIN.getpass('GitHub Personal Access Token: ')
      github = Octokit::Client.new(access_token: access_token)

      gems = {}
      gemfiles(github, github_organization) do |gemfile|
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

    def archived_repositories(github, organization)
      github.organization_repositories(organization)
      last_response = github.last_response

      repositories = []
      last_response.data.each do |repository|
        repositories << repository.name if repository.archived
      end
      until last_response.rels[:next].nil?
        last_response = last_response.rels[:next].get
        last_response.data.each do |repository|
          repositories << repository.name if repository.archived
        end
      end
      repositories
    end

    def gemfiles(github, organization)
      archived = archived_repositories(github, organization)
      github.search_code(SEARCH_TERM % organization, per_page: 1000)
      last_response = github.last_response

      matches = []
      last_response.data.items.each do |match|
        matches << match unless archived.include? match.repository.name
      end
      until last_response.rels[:next].nil?
        last_response = last_response.rels[:next].get
        last_response.data.items.each do |match|
          matches << match unless archived.include? match.repository.name
        end
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
        config.banner = USAGE
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
