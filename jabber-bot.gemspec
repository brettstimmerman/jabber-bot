Gem::Specification.new do |s|
  s.name     = 'jabber-bot'
  s.version  = '1.1.1'
  s.author   = 'Brett Stimmerman'
  s.email    = 'brettstimmerman@gmail.com'
  s.homepage = 'http://github/brettstimmerman/jabber-bot'
  s.platform = Gem::Platform::RUBY
  s.summary  = 'Easily create simple regex powered Jabber bots.'

  s.rubyforge_project = 'jabber-bot'

  s.files = [
    'HISTORY',
    'LICENSE',
    'README.rdoc',
    'lib/jabber/bot.rb'
  ]

  s.require_path = 'lib'

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE', 'HISTORY']
  s.rdoc_options << '--title' << 'Jabber::Bot Documentation' <<
                    '--main' << 'README.rdoc' <<
                    '--line-numbers'

  s.required_ruby_version = '>=1.8.4'

  s.add_dependency('xmpp4r-simple', '>=0.8.7')
end