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
    
    # Creates a new Jabber::Bot object with the specified _name_, _jabber_id_
    # and _password_. If _name_ is omitted, _jabber_id_ is used.  The bot will
    # respond to commands from one or more masters specified by _master_. 
    # You may choose to restrict a Jabber::Bot to listen only to its master(s), 
    # or make it a public bot that will listen to anyone.
    #
    # By default, a Jabber::Bot has only a single command, 'help', which will
    # display the full list of commands available in the bot's repertoire.
    #
    # If you choose to make a public bot only the commands you specify as
    # public commands, as well as the default 'help' command, will be publicly 
    # executable.
    #
    #   # A private bot with a single master
    #   bot = Jabber::Bot.new(
    #       :name      => 'PrivateBot',
    #       :jabber_id => 'bot@example.com', 
    #       :password  => 'password',
    #       :master    => 'master@example.com'
    #   )
    #
    #   # A public bot with mutliple masters
    #   masters = ['master1@example.com', 'master2@example.com]
    #   bot = Jabber::Bot.new(
    #       :name      => 'PublicBot',
    #       :jabber_id => 'bot@example.com', 
    #       :password  => 'password',
    #       :master    => masters,
    #       :is_public => true
    #   )
    #
    def initialize(bot_config)
      
      if bot_config[:jabber_id].nil?
        abort 'You must specify a :jabber_id'
      elsif bot_config[:password].nil?
        abort 'You must specify a :password'
      elsif bot_config[:master].nil? or bot_config[:master].length == 0
        abort 'You must specify at least one :master'
      end
      
      @bot_config = bot_config
      
      @bot_config[:is_public] = false if @bot_config[:is_public].nil?

      if @bot_config[:name].nil? or @bot_config[:name].length == 0
        @bot_config[:name] = @bot_config[:jabber_id].sub(/@.+$/, '')
      end
      
      unless bot_config[:master].is_a?(Array)
        @bot_config[:master] = [bot_config[:master]]
      end
      
      @commands = { :spec => [], :meta => {} }
            
      add_command(
        :syntax      => 'help',
        :description => 'Display this help message',
        :regex       => /^help$/,
        :alias       => [ :syntax => '?', :regex => /^\?/ ],
        :is_public   => @bot_config[:is_public]
      ) { |sender, message| help_message(sender) }
    end
    
    # Add a command to the bot's repertoire.
    #
    # Commands consist of a metadata Hash and a callback block. The metadata
    # Hash *must* contain the command syntax and a description of the command 
    # for display with the builtin 'help' command, and a regular expression to 
    # detect the presence of the command in an incoming message.
    #
    # The metadata Hash may optionally contain an array of command aliases. An
    # alias consists of an alias syntax and regex. Aliases allow the bot to 
    # understand command shorthands. For example, the default 'help' command has
    # an alias '?'. Saying either 'help' or '?' will trigger the same command 
    # callback block.
    #
    # The metadata Hash may optionally contain an is_public flag, indicating
    # the bot should respond to *anyone* issuing the command, not just the bot
    # master(s).  Public commands are only truly public if the bot itself has
    # been made public.
    #
    # The specified callback block will be triggered when the bot receives a 
    # message that matches the given command regex (or an alias regex). The 
    # callback block will have access to the sender and the message text (not 
    # including the command), and should either return a String response or 
    # _nil_. If a callback block returns a String response, the response will be
    # delivered to the bot master that issued the command.
    # 
    # Examples:
    #
    #   # Say "puts foo" to the bot and "foo" will be written to $stdout.
    #   # The bot will also respond with "'foo' written to $stdout."
    #   add_command(
    #     :syntax      => 'puts <string>',
    #     :description => 'Write something to $stdout',
    #     :regex       => /^puts\s+.+$/
    #   ) do |message|
    #     puts message
    #     "'#{message}' written to $stdout."
    #   end
    #
    #   # "puts!" is a non-responding version of "puts", and has an alias, "p!"
    #   add_command(
    #     :syntax      => 'puts! <string>',
    #     :description => 'Write something to $stdout (without response)',
    #     :regex       => /^puts!\s+.+$/,
    #     :alias       => [ :syntax => 'p! <string>', :regex => /^p!$/ ]
    #   ) do |message|
    #     puts message
    #     nil
    #   end
    #
    #  # 'rand' is a public command that produces a random number from 0 to 10
    #  add_command(
    #   :syntax      => 'rand',
    #   :description => 'Produce a random number from 0 to 10',
    #   :regex       => /^rand$/,
    #   :is_public   => true
    #  ) { rand(10).to_s }
    #
    def add_command(command, &callback)
      syntax    = command[:syntax]
      is_public = command[:is_public] || false
      
      # Add the command meta. Using a Hash allows for Hash.sort to list
      # commands aphabetically in the 'help' command response.
      @commands[:meta][syntax] = {
        :syntax      => [syntax],
        :description => command[:description],
        :is_public   => is_public
      }
      
      # Add the command spec. The command spec is used by parse_command.
      @commands[:spec] << {
       :regex     => command[:regex],
       :callback  => callback,
       :is_public => is_public
      }
      
      # Add any command aliases to the command meta and spec
      unless command[:alias].nil?
        command[:alias].each do |a|
          @commands[:meta][syntax][:syntax] << a[:syntax]
          
          @commands[:spec] << {
            :regex     => a[:regex],
            :callback  => callback,
            :is_public => is_public            
          }
        end
      end
    end
    
    # Connect the bot, making him available to accept commands.
    def connect
      @jabber = Jabber::Simple.new(@bot_config[:jabber_id], 
          @bot_config[:password])
      
      deliver(@bot_config[:master], "#{@bot_config[:name]} reporting for duty.")
      
      start_listener_thread      
    end
    
    # Deliver a message to the specified recipient(s).  Accepts a single 
    # recipient or an Array of recipients.
    def deliver(to, message)
      if to.is_a?(Array)
        to.each { |t| @jabber.deliver(t, message) }
      else
        @jabber.deliver(to, message)
      end
    end
    
    # Returns the default help message describing the bot's command repertoire.
    # Commands are sorted alphabetically by name.
    def help_message(sender) #:nodoc:
      help_message = "I understand the following commands:\n\n"
      
      is_master = @bot_config[:master].include?(sender)
      
      @commands[:meta].sort.each do |command|
        if command[1][:is_public] == true || is_master
          command[1][:syntax].each { |syntax| help_message += "#{syntax}\n" }
          help_message += "  #{command[1][:description]}\n\n"
        end
      end
      
      return help_message
    end
    
    # Direct access to the underlying
    # Jabber::Simple[http://xmpp4r-simple.rubyforge.org/] object.
    def jabber
      return @jabber
    end
    
    # Access the bot master jabber id(s), as an Array
    def master
      return @bot_config[:master]
    end
    
    # Parses the given command message for the presence of a known command by 
    # testing it against each known command's regex. If a known command is
    # found, the command parameters are passed on to the callback block, minus 
    # the command trigger. If a String result is present it is delivered to the
    # sender.
    #
    # If the bot has not been made public, commands from anyone other than the
    # bot master(s) will be silently ignored.
    def parse_command(sender, message) #:nodoc:
      puts sender + " " + message
      is_master = @bot_config[:master].include?(sender)
      
      if @bot_config[:is_public] or is_master
        
        @commands[:spec].each do |command|
          if command[:is_public] or is_master
            unless (message.strip =~ command[:regex]).nil?
              response = command[:callback].call(sender,
                  message.sub(/.+\s+/, ''))
         
              deliver(sender, response) unless response.nil?
              return
            end
          end
        end
        
        response = "I don't understand '#{message.strip}.' Try saying 'help' " +
            "to see what commands I understand"
        deliver(sender, response)        
        
      end
    end
    
    # Disconnect the bot.  Once the bot has been disconnected, there is no way
    # to restart it by issuing a command.
    def disconnect
      if @jabber.connected?
        deliver(@bot_config[:master], "#{@bot_config[:name]} disconnecting...")
        @jabber.disconnect
      end
    end
    
    # Creates a new Thread dedicated to listening for incoming chat messages.
    # When a chat message is received, the bot checks if the sender is its 
    # master.  If so, it is tested for the presence commands, and processed 
    # accordingly. If the bot itself or the command issued is not made public,
    # a message sent by anyone other than the bot's master is silently ignored.
    #
    # Only the chat message type is supported.  Other message types such as 
    # error and groupchat are not supported.
    def start_listener_thread #:nodoc:
      listener_thread = Thread.new do
        loop do
            @jabber.received_messages do |message|
              # Remove the Jabber resourse, if any
              sender = message.from.to_s.sub(/\/.+$/, '')
              
              if message.type == :chat 
                parse_thread = Thread.new do 
                  parse_command(sender, message.body)
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