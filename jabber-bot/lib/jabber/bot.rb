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

# RubyGems includes
require 'rubygems'
require 'xmpp4r-simple'

module Jabber
  
  # = Jabber::Bot
  #
  # Jabber::Bot makes it simple to create and command a Jabber bot with little
  # fuss. By adding custom commands powered by regular expressions to your bot's
  # repertoire, you and your new bot will be able to accomplish nearly anything.
  #
  # Author::    Brett Stimmerman (mailto:brettstimmerman@gmail.com)
  # Version::   0.1.0
  # Copyright:: Copyright (c) 2007 Brett Stimmerman. All rights reserved.
  # License::   New BSD License (http://opensource.org/licenses/bsd-license.php)
  # Website::   http://socket7.net/software/jabber-bot
  #
  class Bot
    
    # Creates a new Jabber::Bot object that will use the specified _jabber_id_
    # and _password_ to connect to the Jabber server, and that will only respond
    # to commands given to it by _master_id_ (presumably, you).
    #
    # By default, a Jabber::Bot has only a single command, 'help', which will
    # display the full list of commands available in the bot's repertoire.
    #
    #   bot = Jabber::Bot.new('bot@example.com', 'password', 'master@example.com')
    def initialize(jabber_id, password, master_id)
      @master_id = master_id
      @jabber_id = jabber_id
      @password  = password
      
      @command_meta = {}
      @commands     = {}
            
      add_command(
        :command     => 'help',
        :description => 'Display this help message',
        :regex       => /^help$/,
        :aliases     => [{:alias => '?', :regex => /^\?/}]
      ) { help_message }
    end
    
    # Add a command to the bot's repertoire.
    #
    # Commands consist of a metadata Hash and a callback block. The metadata
    # Hash *must* contain the command's display name (including any syntax
    # guidelines), a description of the command, and a regular expression 
    # describing the command's syntax.
    #
    # The metadata Hash _may_ optionally contain an array of command aliases. An
    # alias consists of a display name and syntax regex. Command aliases allow
    # your bot to understand command shorthands. For example, the default 'help'
    # command has an alias '?'; 'help' and '?' are interchangeable.
    #
    # The specified callback block will be called when the bot receives a 
    # message that matches the given command regex (or an alias regex). The 
    # callback block will have access to the message text (not including the 
    # command), and should either return a String response or _nil_. If a
    # callback block returns a String, it will be delivered to the bot's master
    # as a response.
    # 
    # Examples:
    #
    #   # Say "puts foo" to your bot and "foo" will be written to $stdout.
    #   # The bot will respond with "'foo' written to $stdout."
    #   add_command(
    #     :command     => 'puts <string>',
    #     :description => 'Write something to $stdout',
    #     :regex       => /^puts\s+.+$/
    #   ) do |message|
    #     puts message
    #     "'#{message}' written to $stdout."
    #   end
    #
    #   # "puts!" is a non-responding version of "puts", and has two alias
    #   # commands,  "p!" and "!"
    #   add_command(
    #     :command     => 'puts! <string>',
    #     :description => 'Write something to $stdout (without response)',
    #     :regex       => /^puts!\s+.+$/,
    #     :aliases     => [
    #       { :alias => 'p! <string>', :regex => /^p!$/ },
    #       { :alias => '! <string>', :regex => /^!$/ }
    #     ]
    #   ) do |message|
    #     puts message
    #     nil
    #   end
    #
    def add_command(command, &callback)
      command_name = command[:command]
      
      @command_meta[command_name] = {
        :names       => [command_name],
        :description => command[:description]
      }
      
      @commands[command[:regex]] = callback
      
      # Add any command aliases
      unless command[:aliases].nil?
        command[:aliases].each do |a|
          @command_meta[command_name][:names] << a[:alias]
          @commands[a[:regex]] = callback
        end
      end
    end
    
    # Connect the bot, making him available to accept commands.
    def connect
      @jabber = Jabber::Simple.new(@jabber_id, @password)

      for sig in [:SIGINT, :SIGTERM]
        trap(sig) { abort 'Ook. Jabber::Bot interrupted.' }
      end
      
      deliver('What is your bidding, master?')
      
      start_listener_thread      
    end
    
    # Deliver a message to the bot's master
    def deliver(message)
      @jabber.deliver(@master_id, message)
    end
    
    # Returns the default help message describing the bot's command repertoire.
    # Commands are sorted alphabetically by name.
    def help_message #:nodoc:
      help_message = "I understand the following commands:\n\n"
            
      @command_meta.sort.each do |command|
        command[1][:names].each { |name| help_message += "#{name}\n" }
        help_message += "  #{command[1][:description]}\n\n"
      end
      
      return help_message
    end
    
    # Direct access to the underlying
    # Jabber::Simple[http://xmpp4r-simple.rubyforge.org/] object.
    def jabber
      return @jabber
    end
    
    # Parses the given string for the presence of a known command by testing the
    # string against each known command's regex. If a known command is found
    # the string is passed on to the callback block, minus the command itself.
    # If a String result is is present it is delivered to the bot's master.
    def parse_command(message_str) #:nodoc:
      @commands.each do |regex, callback|
        unless (message_str.strip =~ regex).nil?
          response = callback.call(message_str.sub(/\w+\s+/, ''))
         
          deliver(response) unless response.nil?
          return
        end
      end
        
      response = "I don't understand '#{message_str.strip}.' Try saying " +
        "'help' to see what commands I understand"
      deliver(response)
    end
    
    # Disconnect the bot.  Once the bot has been disconnected, there is no way
    # to restart it by issuing a command.
    def disconnect
      if @jabber.connected?
        deliver('Disconnecting...')
        @jabber.disconnect
      end
    end
    
    # Creates a new Thread dedicated to listening for incoming chat messages.
    # When a chat message is received, the bot checks if the sender is its 
    # master.  If so, it is tested for the presence commands, and processed 
    # accordingly. Messages sent by anyone other than the bot's master are 
    # silently ignored.
    #
    # Only the chat message type is supported.  Other message types such as 
    # error and groupchat are not supported.
    def start_listener_thread #:nodoc:
      listener_thread = Thread.new do
        loop do
            @jabber.received_messages do |message|
              # Remove the Jabber resourse, if any
              sender = message.from.to_s.sub(/\/.+$/, '')
              
              if sender == @master_id and message.type == :chat 
                parse_thread = Thread.new do 
                  parse_command(message.body)
                end
                
                parse_thread.join
              end
            end
          
          sleep 1
        end
      end
      
      listener_thread.join
    end
    
  end
end