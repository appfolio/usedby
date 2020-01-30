# frozen_string_literal: true

require 'test_helper'

class VersionRangesIntersectionTest < MiniTest::Test

  using VersionRangesIntersection

  def test_intersect__identity
    gem_req = Gem::Requirement.new("~> 1.5")

    ranges = Bundler::VersionRanges.for(gem_req)

    assert_equal 1, ranges[0].size
    assert ranges[0][0].intersect?(ranges[0][0])
  end

  def test_intersect__unbounded
    gem_req = Gem::Requirement.new("3.5")
    unbounded_gem_req = Gem::Requirement.new

    ranges = Bundler::VersionRanges.for(gem_req)
    others = Bundler::VersionRanges.for(unbounded_gem_req)

    assert_equal 1, ranges[0].size
    assert_equal 1, others[0].size
    assert ranges[0][0].intersect?(others[0][0])
    assert others[0][0].intersect?(ranges[0][0])
    assert others[0][0].intersect?(others[0][0])
  end

  def test_intersect__no_overlap
    gem_req = Gem::Requirement.new("<= 38", ">= 40")

    ranges = Bundler::VersionRanges.for(gem_req)

    assert_equal 2, ranges[0].size
    refute ranges[0][0].intersect?(ranges[0][1])
    refute ranges[0][1].intersect?(ranges[0][0])
  end

  def test_intersect__overlap
    gem_req = Gem::Requirement.new(">= 38", "< 40")

    ranges = Bundler::VersionRanges.for(gem_req)

    assert_equal 2, ranges[0].size
    assert ranges[0][0].intersect?(ranges[0][1])
    assert ranges[0][1].intersect?(ranges[0][0])
  end

  def test_intersection__no_overlap
    gem_req = Gem::Requirement.new("< 38", "> 40")

    ranges = Bundler::VersionRanges.for(gem_req)

    assert_equal 2, ranges[0].size
    assert_nil ranges[0][0].intersection(ranges[0][1])
  end

  def test_intersection__overlap
    gem_req = Gem::Requirement.new(">= 38", "< 40")

    ranges = Bundler::VersionRanges.for(gem_req)

    assert_equal 2, ranges[0].size
    assert_equal "[0.a, 40)", ranges[0][0].to_s
    assert_equal "[38, ∞)", ranges[0][1].to_s

    intersecting_ranges1 = ranges[0][0].intersection(ranges[0][1])
    intersecting_ranges2 = ranges[0][1].intersection(ranges[0][0])

    assert_equal "[38, 40)", intersecting_ranges1.to_s
    assert_equal "[38, 40)", intersecting_ranges2.to_s
  end

  def test_intersection__identity
    gem_req = Gem::Requirement.new("~> 1.5")

    ranges = Bundler::VersionRanges.for(gem_req)

    assert_equal 1, ranges[0].size
    assert_equal ranges[0][0], ranges[0][0].intersection(ranges[0][0])
  end

  def test_reduce__identity
    gem_req = Gem::Requirement.new("~> 1.5")
    ranges = Bundler::VersionRanges.for(gem_req)

    assert_equal 1, ranges[0].size

    assert_equal [ranges[0][0]], Bundler::VersionRanges::ReqR.reduce(ranges[0])
  end

  def test_reduce__overlap
    gem_req = Gem::Requirement.new(">= 38", "< 40")
    ranges = Bundler::VersionRanges.for(gem_req)
    assert_equal Array, ranges[0].class
    assert_equal 2, ranges[0].size
    assert_equal Bundler::VersionRanges::ReqR, ranges[0][0].class

    reduced_reqrs = Bundler::VersionRanges::ReqR.reduce(ranges[0])

    assert_equal Array, reduced_reqrs.class
    assert_equal Bundler::VersionRanges::ReqR, reduced_reqrs[0].class
    assert_equal 1, reduced_reqrs.size
    assert_equal '[38, 40)', reduced_reqrs[0].to_s
  end

  def test_reduce__redundancy
    gem_req = Gem::Requirement.new(">= 38", "< 40", "< 42")
    ranges = Bundler::VersionRanges.for(gem_req)
    assert_equal Array, ranges[0].class
    assert_equal 3, ranges[0].size
    assert_equal Bundler::VersionRanges::ReqR, ranges[0][0].class

    reduced_reqrs = Bundler::VersionRanges::ReqR.reduce(ranges[0])

    assert_equal Array, reduced_reqrs.class
    assert_equal Bundler::VersionRanges::ReqR, reduced_reqrs[0].class
    assert_equal 1, reduced_reqrs.size
    assert_equal '[38, 40)', reduced_reqrs[0].to_s
  end

  def test_reduce__no_reduction
    # invalid requirement should stay invalid after reduce
    gem_req = Gem::Requirement.new(">= 2", "< 1")
    ranges = Bundler::VersionRanges.for(gem_req)
    assert_equal Array, ranges[0].class
    assert_equal 2, ranges[0].size
    assert_equal Bundler::VersionRanges::ReqR, ranges[0][0].class
    refute ranges[0][0].intersect?(ranges[0][1])

    reduced_reqrs = Bundler::VersionRanges::ReqR.reduce(ranges[0])

    assert_equal Array, reduced_reqrs.class
    assert_equal Bundler::VersionRanges::ReqR, reduced_reqrs[0].class
    assert_equal 2, reduced_reqrs.size
    assert_equal ranges[0], reduced_reqrs
    end
end
