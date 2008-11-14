#!/bin/sh


testfile=/home/webcracy/twitterbot/lib/computerbot_lib.rb.pid

if [ ! -f $testfile ];
then
cd /home/webcracy/twitterbot/
ruby computerbot.rb start
fi
