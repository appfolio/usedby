# frozen_string_literal: true

module VersionRangesIntersection
  refine Bundler::VersionRanges::ReqR do
    # Checks whether two ranges overlap
    def intersect?(other)
      a = self
      b = other

      case a <=> b
      when 0
        return true
      when 1
        b = self
        a = other
      end

      # invariant: a.left < b.left

      case a.right <=> b.left
      when 1
        return true
      end

      false
    end

    # Returns a new range which is the intersection, or else nil
    def intersection(other)
      return nil unless intersect?(other)

      a = clone
      b = other

      case a <=> b
      when -1
        a.left = b.left
      when 1
        a.right = b.right
      end

      a
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
