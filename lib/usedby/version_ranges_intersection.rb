# frozen_string_literal: true

require 'bundler/version_ranges'

module VersionRangesIntersection
  refine Bundler::VersionRanges::ReqR do
    # Checks whether two ranges overlap
    def intersect?(other)
      case self <=> other
      when -1
        return (right <=> other.left) == 1
      when 1
        return (other.right <=> left) == 1
      end

      true
    end

    # Returns a new range which is the intersection, or else nil
    def intersection(other)
      return nil unless intersect?(other)

      inter = clone
      case inter <=> other
      when -1
        inter.left = other.left
      when 1
        inter.right = other.right
      end

      inter
    end
  end

  # Class methods need to be refined on the singleton_class
  refine Bundler::VersionRanges::ReqR.singleton_class do
    def reduce(reqrs = [])
      reduced_reqrs = reqrs.clone
      i = 0
      while i < reduced_reqrs.size - 1
        intersecting_range = reduced_reqrs[i].intersection(reduced_reqrs[i + 1])
        if intersecting_range
          reduced_reqrs[i + 1] = intersecting_range
          reduced_reqrs.delete_at(i)
        else
          i += 1
        end
      end

      reduced_reqrs
    end
  end
end
