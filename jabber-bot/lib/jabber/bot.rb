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
  # Version::   1.1.0
  # Copyright:: Copyright (c) 2007 Brett Stimmerman. All rights reserved.
  # License::   New BSD License (http://opensource.org/licenses/bsd-license.php)
  # Website::   http://socket7.net/software/jabber-bot
  #
  class Bot

    # Direct access to the underlying
    # Jabber::Simple[http://xmpp4r-simple.rubyforge.org/] object.
    attr_reader :jabber

    # Creates a new Jabber::Bot object with the specified +config+ Hash, which
    # must contain +jabber_id+, +password+, and +master+ at a minimum.
    #
    # You may optionally give your bot a custom +name+. If +name+ is omitted,
    # the username portion of +jabber_id+ is used instead.
    #
    # You may choose to restrict a Jabber::Bot to listen only to its master(s),
    # or make it +public+.
    #
    # You may optionally specify a Jabber +presence+, +status+, and +priority+.
    # If omitted, they each default to +nil+.
    #
    # By default, a Jabber::Bot has only a single command, 'help [<command>]',
    # which displays a help message for the specified command, or all commands
    # if <command> is omitted.
    #
    # If you choose to make a public bot, only the commands you specify as
    # public, as well as the default 'help' command, will be public.
    #
    #   # A minimally confiugured private bot with a single master.
    #   bot = Jabber::Bot.new(
    #     :jabber_id => 'bot@example.com',
    #     :password  => 'password',
    #     :master    => 'master@example.com'
    #   )
    #
    #   # A highly configured public bot with a custom name, mutliple masters,
    #   # Jabber presence, status, and priority.
    #   masters = ['master1@example.com', 'master2@example.com']
    #
    #   bot = Jabber::Bot.new(
    #     :name      => 'PublicBot',
    #     :jabber_id => 'bot@example.com',
    #     :password  => 'password',
    #     :master    => masters,
    #     :is_public => true,
    #     :presence  => :chat,
    #     :priority  => 5,
    #     :status    => 'Hello, I am PublicBot.'
    #   )
    #
    def initialize(config)
      @config = config

      @config[:is_public] ||= false

      if @config[:name].nil? or @config[:name].length == 0
        @config[:name] = @config[:jabber_id].sub(/@.+$/, '')
      end

      unless @config[:master].is_a?(Array)
        @config[:master] = [@config[:master]]
      end

      @commands = { :spec => [], :meta => {} }

      add_command(
        :syntax      => 'help [<command>]',
        :description => 'Display help for the given command, or all commands' +
            ' if no command is specified',
        :regex => /^help(\s+?.+?)?$/,
        :alias => [ :syntax => '? [<command>]', :regex  => /^\?(\s+?.+?)?$/ ],
        :is_public => @config[:is_public]
      ) { |sender, message| help_message(sender, message) }
    end

    # Add a command to the bot's repertoire.
    #
    # Commands consist of a metadata Hash and a callback block. The metadata
    # Hash *must* contain the command +syntax+, a +description+ for display with
    # the builtin 'help' command, and a regular expression (+regex+) to detect
    # the presence of the command in an incoming message.
    #
    # The metadata Hash may optionally contain an array of command aliases. An
    # +alias+ consists of an alias +syntax+ and +regex+. Aliases allow the bot
    # to understand command shorthands. For example, the default 'help' command
    # has an alias '?'. Saying either 'help' or '?' will trigger the same
    # command callback block.
    #
    # The metadata Hash may optionally contain a +is_public+ flag, indicating
    # the bot should respond to *anyone* issuing the command, not just the bot
    # master(s). Public commands are only truly public if the bot itself has
    # been made public.
    #
    # The specified callback block will be triggered when the bot receives a
    # message that matches the given command regex (or an alias regex). The
    # callback block will have access to the sender and the message text (not
    # including the command itsef), and should either return a String response 
    # or +nil+. If a callback block returns a String response, the response will
    # be delivered to the Jabber id that issued the command.
    #
    # Examples:
    #
    #   # Say 'puts foo' or 'p foo' and 'foo' will be written to $stdout.
    #   # The bot will also respond with "'foo' written to $stdout."
    #   add_command(
    #     :syntax      => 'puts <string>',
    #     :description => 'Write something to $stdout',
    #     :regex       => /^puts\s+.+$/,
    #     :alias       => [ :syntax => 'p <string>', :regex => /^p\s+.+$/ ]
    #   ) do |sender, message|
    #     puts "#{sender} says #{message}."
    #     "'#{message}' written to $stdout."
    #   end
    #
    #   # 'puts!' is a non-responding version of 'puts', and has two aliases,
    #   # 'p!' and '!'
    #   add_command(
    #     :syntax      => 'puts! <string>',
    #     :description => 'Write something to $stdout (without response)',
    #     :regex       => /^puts!\s+.+$/,
    #     :alias       => [ 
    #       { :syntax => 'p! <string>', :regex => /^p!\s+.+$/ },
    #       { :syntax => '! <string>', :regex => /^!\s+/.+$/ }
    #     ]
    #   ) do |sender, message|
    #     puts "#{sender} says #{message}."
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
      name = command_name(command[:syntax])

      # Add the command meta - used in the 'help' command response.
      add_command_meta(name, command)

      # Add the command spec - used for parsing incoming commands.
      add_command_spec(command, callback)

      # Add any command aliases to the command meta and spec
      unless command[:alias].nil?
        command[:alias].each { |a| add_command_alias(name, a, callback) }
      end
    end

    # Connect the bot, making it available to accept commands.
    def connect
      @jabber = Jabber::Simple.new(@config[:jabber_id], @config[:password])

      presence(@config[:presence], @config[:status], @config[:priority])

      deliver(@config[:master], "#{@config[:name]} reporting for duty.")

      start_listener_thread
    end

    # Deliver a message to the specified recipient(s). Accepts a single
    # recipient or an Array of recipients.
    def deliver(to, message)
      if to.is_a?(Array)
        to.each { |t| @jabber.deliver(t, message) }
      else
        @jabber.deliver(to, message)
      end
    end

    # Disconnect the bot.  Once the bot has been disconnected, there is no way
    # to restart it by issuing a command.
    def disconnect
      if @jabber.connected?
        deliver(@config[:master], "#{@config[:name]} disconnecting...")
        @jabber.disconnect
      end
    end

    # Returns an Array of masters
    def master
      @config[:master]
    end

    # Returns +true+ if the given Jabber id is a master, +false+ otherwise.
    def master?(jabber_id)
      @config[:master].include? jabber_id
    end

    # Sets the bot presence, status message and priority.
    def presence(presence=nil, status=nil, priority=nil)
      @config[:presence] = presence
      @config[:status]   = status
      @config[:priority] = priority

      status_message = Presence.new(presence, status, priority)
      @jabber.send!(status_message) if @jabber.connected?
    end

    # Sets the bot presence. If you need to set more than just the presence,
    # use presence() instead.
    #
    # Available values for presence are:
    #
    #   * nil   : online
    #   * :chat : free for chat
    #   * :away : away from the computer
    #   * :dnd  : do not disturb
    #   * :xa   : extended away
    #
    def presence=(presence)
      presence(presence, @config[:status], @config[:priority])
    end

    # Set the bot priority. Priority is an integer from -127 to 127. If you need
    # to set more than just the priority, use presence() instead.
    def priority=(priority)
      presence(@config[:presence], @config[:status], priority)
    end

    # Set the status message. A status message is just a String, e.g. 'I am
    # here.' or 'Out to lunch.' If you need to set more than just the status
    # message, use presence() instead.
    def status=(status)
      presence(@config[:presence], status, @config[:priority])
    end

    private

    # Add a command alias for the given original +command_name+
    def add_command_alias(command_name, alias_command, callback) #:nodoc:
      original_command = @commands[:meta][command_name]
      original_command[:syntax] << alias_command[:syntax]

      alias_name = command_name(alias_command[:syntax])

      alias_command[:is_public] = original_command[:is_public]

      add_command_meta(alias_name, original_command, true)
      add_command_spec(alias_command, callback)
    end

    # Add a command meta
    def add_command_meta(name, command, is_alias=false) #:nodoc:
      syntax = command[:syntax]

      @commands[:meta][name] = {
        :syntax      => syntax.is_a?(Array) ? syntax : [syntax],
        :description => command[:description],
        :is_public   => command[:is_public] || false,
        :is_alias    => is_alias
      }
    end

    # Add a command spec
    def add_command_spec(command, callback) #:nodoc:
      @commands[:spec] << {
        :regex     => command[:regex],
        :callback  => callback,
        :is_public => command[:is_public] || false
      }
    end

    # Extract the command name from the given syntax
    def command_name(syntax) #:nodoc:
      if syntax.include? ' '
        syntax.sub(/^(\S+).*/, '\1')
      else
        syntax
      end
    end

    # Returns the default help message describing the bot's command repertoire.
    # Commands are sorted alphabetically by name, and are displayed according
    # to the bot's and the commands's _public_ attribute.
    def help_message(sender, command_name) #:nodoc:
      if command_name.nil? or command_name.length == 0
        # Display help for all commands
        help_message = "I understand the following commands:\n\n"

        @commands[:meta].sort.each do |command|
          # Thank you, Hash.sort
          command = command[1]

          if !command[:is_alias] and (command[:is_public] or master? sender)
            command[:syntax].each { |syntax| help_message += "#{syntax}\n" }
            help_message += "  #{command[:description]}\n\n"
          end
        end
      else
        # Display help for the given command
        command = @commands[:meta][command_name]

        if command.nil?
          help_message = "I don't understand '#{command_name}' Try saying" +
              " 'help' to see what commands I understand."
        else
          help_message = ''
          command[:syntax].each { |syntax| help_message += "#{syntax}\n" }
          help_message += "  #{command[:description]} "
        end
      end

      help_message
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
      is_master = master? sender

      if @config[:is_public] or is_master
        @commands[:spec].each do |command|
          if command[:is_public] or is_master
            unless (message.strip =~ command[:regex]).nil?
              params = nil

              if message.include? ' '
                params = message.sub(/^\S+\s+(.*)$/, '\1')
              end

              response = command[:callback].call(sender, params)
              deliver(sender, response) unless response.nil?
              
              return
            end
          end
        end

        response = "I don't understand '#{message.strip}' Try saying 'help' " +
            "to see what commands I understand."
        deliver(sender, response)
      end
    end

    # Creates a new Thread dedicated to listening for incoming chat messages.
    # When a chat message is received, the bot checks if the sender is its
    # master. If so, it is tested for the presence commands, and processed
    # accordingly. If the bot itself or the command issued is not made public,
    # a message sent by anyone other than the bot's master is silently ignored.
    #
    # Only the chat message type is supported. Other message types such as
    # error and groupchat are not supported.
    def start_listener_thread #:nodoc:
      listener_thread = Thread.new do
        loop do
          if @jabber.received_messages?
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
          end

          sleep 1
        end
      end

      listener_thread.join
    end

  end
end