# frozen_string_literal: true

require_relative 'lib/usedby/version'

Gem::Specification.new do |s|
  s.author = 'Bryce Boe'
  s.description = <<~DESCRIPTION
    usedby is a command line tool to allow one to
    discover ruby gem dependencies for all ruby projects across a github
    organization..
  DESCRIPTION
  s.email = 'bryce.boe@appfolio.com'
  s.executables = %(usedby)
  s.files = Dir.glob('{bin,lib}/**/*') + %w[CHANGES.md LICENSE.txt README.md]
  s.homepage = 'https://github.com/appfolio/usedby'
  s.license = 'BSD-2-Clause'
  s.name = 'usedby'
  s.summary = 'Discover all ruby gem dependencies for a github organization.'
  s.version = Usedby::VERSION

  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rake', '~> 12.0'

  s.add_runtime_dependency 'octokit', '~> 4.0'
end
