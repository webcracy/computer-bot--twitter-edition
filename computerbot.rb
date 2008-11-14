  ##########################################################################
  #
  #   Welcome to Computerbot's source, Twitterbot version.
  #   Copyright 2008 Alexandre Loureiro Solleiro <alex@webcracy.org>, http://webcracy.org
  #   All rights reserved.
  #   You are free to use, modify and distribute binary and source copies of this application. 
  #   Be nice if you do. It's my right to demand it.
  #   This notice must never be separated from the code and you must give me credit for binary or source use.
  #   Read and respect the licenses of third-party software distributed with this package.
  #   Author: Alexandre Loureiro Solleiro <alex@webcracy.org>
  #   Contact: alex@webcracy.org
  #   Website: http://computer.webcracy.org/
  #   Documentation: http://computer.webcracy.org/doc/
  #   Tutorials: http://computer.webcracy.org/tutorials/
  #   Have fun.
  #   --------
  #   To start (runs in the background): ruby computerbot.rb start 'env'
  #   To restart: ruby computerbot.rb restart 'env'
  #   To stop: ruby computerbot.rb stop
  #   To run in the foreground (debug mode): ruby computerbot.rb run 'env'
  # 
  ########################################################################


require 'rubygems'
require 'daemons'

def whatstheenv?(envi)
  if envi != nil
    return envi
  elsif envi == nil
    return 'config'
  end
end

ENV_SET = whatstheenv?(ARGV[1])

if ARGV[0].to_s == 'start' or ARGV[0].to_s == 'run'
  puts "___ Bot running in #{ENV_SET} environnement..."
  puts "___ You can edit computerbot.rb to use other configs"
  puts "___ Type 'ruby computerbot.rb stop' to disconnect the bot"
elsif ARGV[0].to_s == 'restart'
  puts "___ Bot restarted in #{ENV_SET} environnement..."
  puts "___ Type 'ruby computerbot.rb stop' to disconnect the bot"
else
  puts "___ Bot disconnected."
end

Daemons.run('lib/computerbot_lib.rb')