# frozen_string_literal: true

require 'base64'
require 'io/console'
require 'json'
require 'octokit'
require 'optparse'
require 'organization_gem_dependencies/version_ranges_intersection'

module OrganizationGemDependencies
  # Define the command line interface.
  class Cli
    using VersionRangesIntersection

    GEMFILE_LOCK_SEARCH_TERM = 'org:%s filename:Gemfile.lock'
    GEMSPEC_SEARCH_TERM = 'org:%s extension:gemspec'
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

      remote_search(github, github_organization, GEMFILE_LOCK_SEARCH_TERM) do |gemfile_lock|
        content = Bundler::LockfileParser.new(remote_file(github, gemfile_lock))
        merge!(gems, process_gemfile(content, "#{gemfile_lock.repository.name}/#{gemfile_lock.path}"))
      end

      remote_search(github, github_organization, GEMSPEC_SEARCH_TERM) do |gemspec|
        content = remote_file(github, gemspec)
        merge!(gems, process_gemspec(content, "#{gemspec.repository.name}/#{gemspec.path}"))
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
        sleep_time = 0
        begin
          last_response = last_response.rels[:next].get
        rescue StandardError
          sleep_time += 1
          STDERR.puts "Sleeping #{sleep_time} seconds"
          sleep(sleep_time)
          retry
        end
        last_response.data.each do |repository|
          repositories << repository.name if repository.archived
        end
      end
      repositories
    end

    def build_ignore_paths(ignored_paths, file)
      File.open(file).each do |line|
        cleaned = line.strip
        ignored_paths << cleaned if cleaned != ''
      end
    rescue Errno::ENOENT, Errno::EISDIR
      STDERR.puts "No such file #{file}"
      exit 1
    end

    def filtered?(gemfile_path)
      @options[:ignore_paths].each do |ignore_path|
        return true if gemfile_path.start_with?(ignore_path)
      end
      false
    end

    def remote_search(github, organization, search_term)
      archived = archived_repositories(github, organization)
      github.search_code(search_term % organization, per_page: 1000)
      last_response = github.last_response

      matches = []
      last_response.data.items.each do |match|
        matches << match unless archived.include? match.repository.name
      end
      until last_response.rels[:next].nil?
        sleep_time = 0
        begin
          last_response = last_response.rels[:next].get
        rescue StandardError
          sleep_time += 1
          STDERR.puts "Sleeping #{sleep_time} seconds"
          sleep(sleep_time)
          retry
        end
        last_response.data.items.each do |match|
          matches << match unless archived.include? match.repository.name
        end
      end

      matches.sort_by(&:html_url).each do |match|
        yield match
      end
    end

    def remote_file(github, file)
      github_path = "#{file.repository.name}/#{file.path}"
      if filtered?(github_path)
        STDERR.puts "Skipping #{github_path}"
        return
      end
      STDERR.puts "Processing #{github_path}"
      sleep_time = 0
      begin
        content = Base64.decode64(github.get(file.url).content)
      rescue StandardError
        sleep_time += 1
        STDERR.puts "Sleeping #{sleep_time} seconds"
        sleep(sleep_time)
        retry
      end
      content
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
          sorted_gems[gem][version_ranges_to_s(version)] = projects.sort
        end
      end
      puts JSON.pretty_generate(sorted_gems)
    end

    def parse_options
      @options = { direct: false, ignore_paths: [] }
      OptionParser.new do |config|
        config.banner = USAGE
        config.on('-d', '--direct',
                  'Consider only direct dependencies.') do |direct|
          @options[:direct] = direct
        end
        config.on('-i', '--ignore-file [FILEPATH]',
                  'Ignore projects included in file.') do |ignore_file|

          build_ignore_paths(@options[:ignore_paths], ignore_file)
        end
        config.on('-g', '--gems [GEM1,GEM2,GEM3]',
                  'Consider only given gems.') do |gems|

          @options[:gems] = gems.split(',')
        end
        config.version = OrganizationGemDependencies::VERSION
      end.parse!
    end

    def process_gemfile(gemfile, project)
      dependencies = gemfile.dependencies.map { |dependency, _, _| dependency }
      gems = {}

      gemfile.specs.each do |spec|
        next if @options[:direct] && !dependencies.include?(spec.name)
        next if @options[:gems] && !@options[:gems].include?(spec.name)
        spec_version_ranges = Bundler::VersionRanges.for(Gem::Requirement.new(spec.version))
        gems[spec.name] = {}
        gems[spec.name][spec_version_ranges] = [project]
      end
      gems
    end

    # Process dependencies in gemspec according to:
    # https://guides.rubygems.org/specification-reference/
    # Sample supported formats:
    #      s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
    #   spec.add_runtime_dependency "multi_json", "~>1.12", ">=1.12.0"
    # Sample unsupported formats:
    #      s.add_development_dependency "rake", "~> 10.5" if on_less_than_1_9_3?
    #      s.add_dependency 'sunspot', Sunspot::VERSION
    def process_gemspec(content, project)
      gems = {}
      dummy_spec = Gem::Specification.new
      content.each_line do |line|
        if line =~ /^\s*(\w+)\.add_(development_dependency|runtime_dependency|dependency)\b/
          spec_name = $1
          begin
            eval line.sub(spec_name, 'dummy_spec')
          rescue => e
            $stderr.puts e
            next
          end
          dep = dummy_spec.dependencies.last
          gem_name = dep.name
          next if @options[:gems] && !@options[:gems].include?(gem_name)
          gem_version_ranges = Bundler::VersionRanges.for(dep.requirement)
          gems[gem_name] = {}
          gems[gem_name][gem_version_ranges] = [project]
        end
      end
      gems
    end

    # Uses mathematical notation for ranges
    # The unbounded range is [0, ∞)
    def version_ranges_to_s(gem_version_ranges)
      if !gem_version_ranges.kind_of?(Array) || gem_version_ranges.size != 2
        $stderr.puts "Unknown format for version ranges: #{gem_version_ranges}"
        return ""
      end

      # base case: a specific version
      if gem_version_ranges[0].size == 1
        range = gem_version_ranges[0][0]
        if range.left.version == range.right.version
          return range.left.version.to_s
        end
      end

      gem_version_ranges[0] = Bundler::VersionRanges::ReqR.reduce(gem_version_ranges[0])

      arr = []
      gem_version_ranges[0].each do |reqr|
        range_begin = reqr.left.inclusive ? "[" : "("
        range_end = reqr.right.inclusive ? "]" : ")"
        arr << "#{range_begin}#{reqr.left.version.to_s}, #{reqr.right.version.to_s}#{range_end}"
      end
      gem_version_ranges[1].each do |neq|
        # special case: exclude specific version
        arr << "!= #{neq.version.to_s}"
      end
      arr.join(", ")
    end
  end
end
