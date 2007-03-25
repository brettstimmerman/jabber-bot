#--
# Copyright (c) 2007 Brett Stimmerman <brettstimmerman@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

require 'rubygems'

Gem::manage_gems

require 'rake/gempackagetask'
require 'rake/rdoctask'

spec = Gem::Specification.new do |s|
  s.name     = 'jabber-bot'
  s.version  = '1.1.0'
  s.author   = 'Brett Stimmerman'
  s.email    = 'brettstimmerman@gmail.com'
  s.homepage = 'http://socket7.net/software/jabber-bot'
  s.platform = Gem::Platform::RUBY
  s.summary  = "Jabber::Bot makes it simple to create and command your own " +
               "Jabber bot with little fuss. By adding custom commands " +
               "powered by regular expressions to your bot's repertoire, you " +
               "and your new bot will be able to accomplish nearly anything."

  s.rubyforge_project = 'jabber-bot'

  s.files = FileList['lib/**/*', 'LICENSE', 'README',
      'HISTORY'].exclude('rdoc').to_a

  s.require_path = 'lib'

  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'LICENSE', 'HISTORY']
  s.rdoc_options << '--title' << 'Jabber::Bot Documentation' <<
                    '--main' << 'README' <<
                    '--line-numbers'

  s.required_ruby_version = '>=1.8.4'

  s.add_dependency('xmpp4r-simple', '>=0.8.7')
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

Rake::RDocTask.new do |rd|
  rd.main     = 'README'
  rd.title    = 'Jabber::Bot Documentation'
  rd.rdoc_dir = 'doc/html'
  rd.rdoc_files.include('README', 'lib/**/*.rb')
end