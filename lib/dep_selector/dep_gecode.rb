#
# Author:: Daniel DeLeo (<dan@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'ffi'

module Dep_gecode

  extend FFI::Library

  lib_dir = File.expand_path("../../", __FILE__)
  lib_dir_path = Dir["#{lib_dir}/dep_gecode.*"].first

  ext_dir = File.expand_path("../../../ext/dep_gecode/", __FILE__)
  ext_dir_path = Dir["#{ext_dir}/dep_gecode.*"].first

  path = lib_dir_path || ext_dir_path

  # FFI will load the library by calling LoadLibraryExA. The docs for this
  # function advise not to use forward slashes (though this does work at least
  # in at least some cases).
  # See: http://msdn.microsoft.com/en-us/library/windows/desktop/ms684179(v=vs.85).aspx
  path.gsub!('/', '\\') if RUBY_PLATFORM =~ /mswin|mingw|windows/

  ffi_lib path

  # VersionProblem * VersionProblemCreate(int packageCount, bool dumpStats, 
  #                                       bool debug, const char * log_id);
  attach_function :VersionProblemCreate, [:int, :bool, :bool, :string], :pointer

  # void VersionProblemDestroy(VersionProblem * vp);
  attach_function :VersionProblemDestroy, [:pointer], :void

  # int AddPackage(VersionProblem *problem, int min, int max, int currentVersion);
  attach_function :AddPackage, [:pointer, :int, :int, :int], :int

  # int VersionProblemSize(VersionProblem *p); 
  attach_function :VersionProblemSize, [:pointer], :int

  # void MarkPackagePreferredToBeAtLatest(VersionProblem *problem, int packageId, int weight);
  attach_function :MarkPackagePreferredToBeAtLatest, [:pointer, :int, :int], :void

  # void MarkPackageRequired(VersionProblem *problem, int packageId);
  attach_function :MarkPackageRequired, [:pointer, :int], :void

  # void AddVersionConstraint(VersionProblem *problem, int packageId, int version,
  #                           int dependentPackageId, int minDependentVersion, int maxDependentVersion);
  attach_function :AddVersionConstraint, [:pointer, :int, :int, :int, :int, :int], :void

  # VersionProblem * Solve(VersionProblem * problem);
  attach_function :Solve, [:pointer], :pointer

  # int GetDisabledVariableCount(VersionProblem *problem);
  attach_function :GetDisabledVariableCount, [:pointer], :int

  # int GetPackageVersion(VersionProblem *problem, int packageId);
  attach_function :GetPackageVersion, [:pointer, :int], :int

  # void MarkPackageSuspicious(VersionProblem *problem, int packageId);
  attach_function :MarkPackageSuspicious, [:pointer, :int], :void

  # bool GetPackageDisabledState(VersionProblem *problem, int packageId);
  attach_function :GetPackageDisabledState, [:pointer, :int], :bool

  # int VersionProblemPackageCount(VersionProblem *p);
  attach_function :VersionProblemPackageCount, [:pointer], :int

  # int GetPackageMax(VersionProblem *problem, int packageId);
  attach_function :GetPackageMax, [:pointer, :int], :int

  # int GetPackageMin(VersionProblem *problem, int packageId);
  attach_function :GetPackageMin, [:pointer, :int], :int
end


