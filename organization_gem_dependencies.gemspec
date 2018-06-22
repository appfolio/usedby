# frozen_string_literal: true

require_relative 'lib/organization_gem_dependencies/version'

Gem::Specification.new do |s|
  s.author = 'Bryce Boe'
  s.description = <<~DESCRIPTION
    organization_gem_dependencies is a command line tool to allow one to
    discover ruby gem dependencies for all ruby projects across a github
    organization..
  DESCRIPTION
  s.email = 'bryce.boe@appfolio.com'
  s.executables = %(worganization_gem_dependencies)
  s.files = Dir.glob('{bin,lib}/**/*') + %w[CHANGES.md LICENSE.txt README.md]
  s.homepage = 'https://github.com/appfolio/organization_gem_dependencies'
  s.license = 'BSD-2-Clause'
  s.name = 'organization_gem_dependencies'
  s.summary = 'Discover all ruby gem depedencies for a github organization.'
  s.version = OrganizationGemDependencies::VERSION

  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rake', '~> 12.0'
end
