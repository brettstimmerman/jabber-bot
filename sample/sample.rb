#!/usr/bin/env ruby

#--
# Copyright (c) 2009 Brett Stimmerman <brettstimmerman@gmail.com>
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
require 'jabber/bot'

# Configure a public bot
config = {
  :name      => 'PublicBot',
  :jabber_id => 'bot@example.com',
  :password  => 'secret',
  :master    => 'master@example.com',
  :is_public => true,
  :status    => 'Hello, I am PublicBot.',
  :presence  => :chat,
  :priority  => 10
}

# Create a new bot
bot = Jabber::Bot.new(config)

# Give the bot a private command, 'puts', with a response message
bot.add_command(
  :syntax      => 'puts <string>',
  :description => 'Write something to $stdout',
  :regex       => /^puts\s+.+$/
) do |sender, message|
  puts "#{sender} says '#{message}'"
  "'#{message}' written to $stdout"
end

# Give the bot another private command, 'puts!', without a response message
bot.add_command(
  :syntax      => 'puts! <string>',
  :description => 'Write something to $stdout',
  :regex       => /^puts!\s+.+$/
) do |sender, message|
  puts "#{sender} says '#{message}'"
  nil
end

# Give the bot a public command, 'rand', with alias 'r'
bot.add_command(
  :syntax      => 'rand',
  :description => 'Produce a random number from 0 to 10',
  :regex       => /^rand$/,
  :alias       => [:syntax => 'r', :regex => /^r$/],
  :is_public   => true
) { rand(10).to_s }

# Unleash the bot
bot.connect