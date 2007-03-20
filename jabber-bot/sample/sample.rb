#!/usr/bin/env ruby
require 'rubygems'
require 'jabber/bot'

# Configure the bot
jabber_id = 'bot@example.com'
password  = 'password'
master_id = 'master@example.com'

# Create a new bot
bot = Jabber::Bot.new(jabber_id, password, master_id)

# Give the bot a new command, 'puts', with a response message
bot.add_command(
  :command     => 'puts <string>',
  :description => 'Write something to $stdout',
  :regex       => /^puts\s+.+$/
) do |message|
  puts message
  "'#{message}' written to $stdout"
end

# Give the bot another command, 'puts!' without a response message
bot.add_command(
  :command     => 'puts! <string>',
  :description => 'Write something to $stdout',
  :regex       => /^puts!\s+.+$/
) do |message|
  puts message
  nil
end

# Give the bot another command, 'rand', with alias 'r'
bot.add_command(
  :command     => 'rand',
  :description => 'Produce a random number from 0 to 10',
  :regex       => /^rand$/,
  :aliases     => [:alias => 'r', :regex => /^r$/]
) { rand(10).to_s }

# Unleash the new bot
bot.connect