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

#
# GECODE needs to be built with 
# ./configure --with-architectures=i386,x86_64
# to work properly here.
require 'mkmf'

$LIBS << " -lstdc++"

# $CFLAGS << "-g"

gecode_installed =
  have_library('gecodesearch') &&
  have_library('gecodeint') &&
  have_library('gecodekernel') &&
  have_library('gecodesupport') &&
  have_library('gecodeminimodel')

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
