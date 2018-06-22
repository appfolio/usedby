# frozen_string_literal: true

require 'minitest/autorun'
require 'organization_gem_dependencies'

class VersionTest < MiniTest::Test
  def test_version
    assert_equal '0.1.0', OrganizationGemDependencies::VERSION
  end
end
