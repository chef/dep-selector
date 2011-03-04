#
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Mark Anderson (<mark@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'dep_selector/exceptions'

module DepSelector
  class DenselyPackedSet
    attr_reader :sorted_elements

    def initialize(elements)
      @sorted_elements = elements.sort
      @element_to_index = {}
      @sorted_elements.each_with_index{|elt, idx| @element_to_index[elt] = idx}
    end

    def range
      Range.new(0, @sorted_elements.size-1)
    end

    def index(element)
      unless @element_to_index.has_key?(element)
        msg = "#{element} is not a valid version for this package"
        raise Exceptions::InvalidVersion.new(msg)
      end
      @element_to_index[element]
    end

    def [](constraint)
      # TODO [cw/mark,2010/11/22]: don't actually need an array here, re-write
      range = []
      started = false
      done = false
      sorted_elements.each_with_index do |element, idx|
        if constraint.include?(element)
          raise "Currently only handle continuous gap between #{range.last} and #{idx} for #{constraint.to_s} over #{@sorted_elements.join(', ')}" if (range.any? && range.last+1 != idx)
          range << idx
        end
      end

      range.empty? ? [] : Range.new(range.first, range.last)
    end
  end
end
