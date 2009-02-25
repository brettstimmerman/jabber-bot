Gem::Specification.new do |s|
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

  s.files = [
    'HISTORY',
    'LICENSE',
    'README',
    'lib/jabber/bot.rb'
  ]

  s.require_path = 'lib'

  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'LICENSE', 'HISTORY']
  s.rdoc_options << '--title' << 'Jabber::Bot Documentation' <<
                    '--main' << 'README' <<
                    '--line-numbers'

  s.required_ruby_version = '>=1.8.4'

  s.add_dependency('xmpp4r-simple', '>=0.8.7')
end