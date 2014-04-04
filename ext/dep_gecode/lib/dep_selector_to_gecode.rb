#!/usr/bin/ruby


require "ffi"

module VersionProblem
  extend FFI::Library
#  ffi_lib FFI:Library:????
  attach_function 'VersionProblemCreate', [ ], :pointer
  attach_function 'VersionProblemDump', [ :pointer ], :void
end
