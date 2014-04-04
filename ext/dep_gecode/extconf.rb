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

  # $CFLAGS << "-g"

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
Gecode >3.5 must be installed (http://www.gecode.org/).

OSX:
  brew install gecode

For convenience, we have built Gecode for Debian/Ubuntu (<release> is lucid or maverick):
  Add the following two lines to /etc/apt/sources.list.d/opscode.list:
    deb http://apt.opscode.com <release> main
    deb-src http://apt.opscode.com <release> main
  Then run:
    curl http://apt.opscode.com/packages@opscode.com.gpg.key | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install libgecode-dev

Other distributions can build from source.
=========================================================================================
EOS
    raise "Gecode not installed"
  end

  create_makefile('dep_gecode')
else # JRUBY

  require 'rbconfig'

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

  # FIXME: add more compilers with default options
  if cc =~ /gcc|clang/
    cflags << "-Wno-error=shorten-64-to-32  -pipe"
    cflags << " -O3" unless cflags =~ /-O\d/
    cflags << " -Wall"
    cppflags << " -O3" unless cppflags =~ /-O\d/
    cppflags << " -fno-common"
  end

  ENV['CFLAGS'] = cflags
  ENV['LDFLAGS'] = ldflags
  ENV['CC'] = cc
  ENV['CXX'] = cxx
  ENV["CPPFLAGS"] = cppflags
  ENV["CXXFLAGS"] = cxxflags

  dlext = RbConfig::CONFIG["DLEXT"]

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
INCFLAGS = -I.
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
