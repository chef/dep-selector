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

# Ruby that supports C extensions. Our library isn't an extension, but we piggyback on ruby's C extension build system
if !defined?(RUBY_ENGINE) || RUBY_ENGINE == 'ruby' || RUBY_ENGINE == 'rbx'
  #
  # GECODE needs to be built with 
  # ./configure --with-architectures=i386,x86_64
  # to work properly here.
  require 'mkmf'
  require 'dep-selector-libgecode'

  opt_path = DepSelectorLibgecode.opt_path
  include_path = DepSelectorLibgecode.include_path
  if find_library("gecodesupport", nil, opt_path)

    # Ruby sometimes has a blank RPATHFLAG, even though it's on a system that
    # really should be setting rpath flags. If there _is_ an rpath flag we'll
    # honor it, but if not, we'll assume that ruby is lying and set it
    # ourselves.
    #
    # See also: https://github.com/opscode/dep-selector/issues/23
    ruby_rpathflag = RbConfig::MAKEFILE_CONFIG["RPATHFLAG"]
    if ruby_rpathflag.nil? || ruby_rpathflag.empty?
      hax_rpath_flags = " -Wl,-rpath,%1$-s" % [opt_path]
      $DLDFLAGS << hax_rpath_flags
    end
  end
  # find_header doesn't seem to work for stuff like `gecode/thing.hh`
  $INCFLAGS << " -I#{include_path}"

  gecode_installed =
    # Gecode documentation notes:
    # "Some linkers require the list of libraries to be sorted such that
    # libraries appear before all libraries they depend on."
    # http://www.gecode.org/doc-latest/MPG.pdf
    #
    # This appears to be true of the version of mingw that ships with Ruby 1.9.3.
    # The correct order of `-l` flags according to the docs is:
    #
    # 1. -lgecodeflatzinc
    # 2. -lgecodedriver
    # 3. -lgecodegist
    # 4. -lgecodesearch,
    # 5. -lgecodeminimodel
    # 6. -lgecodeset
    # 7. -lgecodefloat
    # 8. -lgecodeint
    # 9. -lgecodekernel
    # 10. -lgecodesupport
    #
    # Ruby `mkmf` will add `-l` flags in the _REVERSE_ order that they appear here.
    have_library('gecodesupport') &&
    have_library('gecodekernel') &&
    have_library('gecodeint') &&
    have_library('gecodeminimodel') &&
    have_library('gecodesearch')

  unless gecode_installed
    STDERR.puts <<EOS
=========================================================================================
Gecode ~>3.5 must be installed (http://www.gecode.org/).

OSX:
  cd $( brew --prefix )
  git checkout 3c5ca25 Library/Formula/gecode.rb
  brew install gecode

Debian and Ubuntu:
  sudo apt-get install libgecode-dev

Build from source:
  Get gecode 3.7.3 source:
    curl -O http://www.gecode.org/download/gecode-3.7.3.tar.gz
  Unpack it:
    tar zxvf gecode-3.7.3.tar.gz
  Build:
    ./configure --disable-doc-dot \
           --disable-doc-search \
           --disable-doc-tagfile \
           --disable-doc-chm \
           --disable-doc-docset \
           --disable-qt \
           --disable-examples
    make
    (sudo) make install

=========================================================================================
EOS
    raise "Gecode not installed"
  end

  if RUBY_PLATFORM =~ /mswin|mingw|windows/
    # By default, ruby will generate linker options that will not export the
    # symbols we need to export. We pass an extra def file to the linker to
    # make it export the symbols we need.
    $DLDFLAGS << " -Wl,--enable-auto-image-base,--enable-auto-import dep_gecode-all.def"

    # When compiling with devkit, mingw/bin is added to the PATH only for
    # compilation, but not at runtime. Windows uses PATH for shared library
    # path and has no rpath feature. This means that dynamic linking to
    # libraries in mingw/bin will succeed at compilation but cause runtime
    # loading failures. To fix this we static link libgcc and libstdc++
    # See: https://github.com/opscode/dep-selector/issues/17
    $libs << "  -static-libgcc -static-libstdc++"
  end

  create_makefile('dep_gecode')
else # JRUBY

  require 'rbconfig'
  require 'ffi/platform'

  incflags = "-I."
  libpath = "-L."

  require 'dep-selector-libgecode'
  opt_path = DepSelectorLibgecode.opt_path
  include_path = DepSelectorLibgecode.include_path
  libpath << " -L#{opt_path}"

  # On MRI, RbConfig::CONFIG["RPATHFLAG"] == "" when using clang/llvm, but this
  # isn't set on JRuby so we need to detect llvm manually and set rpath on gcc
  unless `gcc -v` =~ /LLVM/
    rpath_flag = (" -Wl,-R%1$-s" % [opt_path])
    libpath << rpath_flag
  end
  incflags << " -I#{include_path}"

  cflags = ENV['CFLAGS']
  cppflags = ENV['CPPFLAGS']
  cxxflags = ENV['CXXFLAGS']
  ldflags = ENV['LDFLAGS']
  cc = ENV['CC']
  cxx = ENV['CXX']

  ldsharedxx = RbConfig::MAKEFILE_CONFIG["LDSHAREDXX"]

  # use the CC that ruby was compiled with by default
  cc ||= RbConfig::MAKEFILE_CONFIG['CC']
  cxx  ||= RbConfig::MAKEFILE_CONFIG["CXX"]
  cppflags ||= RbConfig::MAKEFILE_CONFIG["CPPFLAGS"]
  cxxflags ||= RbConfig::MAKEFILE_CONFIG["CXXFLAGS"]
  cflags ||= ""
  ldflags ||= ""

  # then ultimately default back to gcc
  cc ||= "gcc"
  cxx ||= "g++"

  # JRuby reports that the compiler is "CC" no matter what, so we can't detect
  # if we're using anything other than gcc/llvm. Therefore we just assume
  # that's the compiler we're on.
  cflags << "-Wno-error=shorten-64-to-32  -pipe"
  cflags << " -O3" unless cflags =~ /-O\d/
  cflags << " -Wall -fPIC"
  cppflags << " -O3" unless cppflags =~ /-O\d/
  cppflags << " -fno-common -fPIC"
  cxxflags << " -O3" unless cppflags =~ /-O\d/
  cxxflags << " -fno-common -fPIC"

  ENV['CFLAGS'] = cflags
  ENV['LDFLAGS'] = ldflags
  ENV['CC'] = cc
  ENV['CXX'] = cxx
  ENV["CPPFLAGS"] = cppflags
  ENV["CXXFLAGS"] = cxxflags
  ENV['INCFLAGS'] = incflags
  ENV['LIBPATH'] = libpath

  dlext = FFI::Platform::LIBSUFFIX

  headers = "$(srcdir)/dep_selector_to_gecode.h $(srcdir)/dep_selector_to_gecode_interface.h"

  install = RbConfig::MAKEFILE_CONFIG["INSTALL"]

  File.open("Makefile", "w") do |mf|
    mf.puts(<<-EOH)
# Makefile for building dep_gecode

# V=0 quiet, V=1 verbose.  other values don't work.
V = 1
Q1 = $(V:1=)
Q = $(Q1:0=@)
ECHO1 = $(V:1=@:)
ECHO = $(ECHO1:0=@echo)

srcdir = .

CFLAGS = #{ENV['CFLAGS']}
LDFLAGS = #{ENV['LDFLAGS']}
CPPFLAGS = #{ENV['CPPFLAGS']}
CXXFLAGS = #{ENV['CXXFLAGS']}
INCFLAGS = #{ENV['INCFLAGS']}
LIBPATH = #{ENV['LIBPATH']}

LDSHAREDXX = #{ldsharedxx}

empty =
OUTFLAG = -o $(empty)
COUTFLAG = -o $(empty)
CC = #{ENV['CC']}
CXX = #{ENV["CXX"]}
TARGET = dep_gecode
TARGET_NAME = dep_gecode
DLLIB = $(TARGET).#{dlext}
LIBS = -lgecodesearch -lgecodeminimodel -lgecodeint -lgecodekernel -lgecodesupport
CLEANLIBS = $(DLLIB)
OBJS = dep_selector_to_gecode.o dep_selector_to_gecode_interface.o
CLEANOBJS = *.o  *.bak
HDRS = #{headers}

INSTALL = #{install}
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644

all:\t$(DLLIB)

install:

clean:
\t$(Q)$(RM) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES) .*.time


.SUFFIXES: .c .m .cc .mm .cxx .cpp .C .o

.cc.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $<

.cxx.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $<

.cpp.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $<

$(DLLIB): $(OBJS) Makefile
	$(ECHO) linking shared-object $(DLLIB)
	-$(Q)$(RM) $(@)
	$(Q) $(LDSHAREDXX) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)
	$(Q) test -z '$(RUBY_CODESIGN)' || codesign -s '$(RUBY_CODESIGN)' -f $@

$(OBJS): $(HDRS)

EOH
  end
end
