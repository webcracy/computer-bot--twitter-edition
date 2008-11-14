require 'rubygems'
require 'yaml'

  # Uses the jabber_bot.rb lib directly instead of the rubygem
require File.dirname(__FILE__) + '/jabber_bot.rb'

  # All plugins are loaded here.
require File.dirname(__FILE__) + '/modules/twitta.rb'

  # Load specified configuration file
  
config = YAML::load(File.open(File.dirname(__FILE__) + "/config/#{ENV_SET}.yml"))

  # Initialize Jabber configuration
  
JABBER_USERNAME = config['jabber']['username']
JABBER_PASSWORD = config['jabber']['password']
JABBER_MASTER = config['jabber']['master']
JABBER_STATUS = config['jabber']['status']

module Computer

class Bot
  
  def initialize
        
    @@bot = Jabber::Bot.new(
      :jabber_id => JABBER_USERNAME, 
      :password  => JABBER_PASSWORD, 
      :master    => JABBER_MASTER,
      :presence => :chat,
      :status => JABBER_STATUS,
      :resource => 'Bot',
      :is_public => false
    )
    
    load_commands
    
    @@bot.connect
    
  end
  
  def self.deliver(sender, message)
    if message.is_a?(Array)
      message.each { |message| @@bot.deliver(sender, message)}
    else
      @@bot.deliver(sender, message)
    end
  end
  
  def deliver(sender, message)
    if message.is_a?(Array)
      message.each { |message| @@bot.deliver(sender, message)}
    else
      @@bot.deliver(sender, message)
    end
  end

  def load_commands
        
    
    @@bot.add_command(
      :syntax      => 'ping',
      :description => 'Returns a pong and a timestamp',
      :regex       => /^ping$/,
      :is_public   => false
    ) { "Pong! (#{Time.now})" }
      
      @@bot.add_command(
         :syntax      => 'me',
         :description => 'Returns the username you are using.',
         :regex       => /^me$/,
         :is_public   => false
       ) do |sender, message|
           execute_twitter_me_command(sender, message)
         nil
       end      
      
      @@bot.add_command(
         :syntax      => 'say <Your tweet>',
         :description => 'Post a message to Twitter',
         :regex       => /^say\s+.+$/,
         :is_public   => false
       ) do |sender, message|
           execute_twitter_say_command(sender, message)
         nil
       end
       
       @@bot.add_command(
        :syntax => 'last <0-9>',
        :description => 'Retrieve X latest posts from your timeline (posts from friends)',
        :regex => /^last\s+.+$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_last_command(sender, message)
        nil
       end

       @@bot.add_command(
        :syntax => 'all',
        :description => 'Retrieve the 20 messages from twitter timeline (posts from friends)',
        :regex => /^all$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_all_command(sender, message)
        nil
       end

       @@bot.add_command(
        :syntax => 'trends',
        :description => 'See what people are talking about.',
        :regex => /^trends$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_trends_command(sender, message)
        nil
       end


       @@bot.add_command(
        :syntax => 'dm',
        :description => 'Retrieve direct messages sent to you',
        :regex => /^dm$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_dm_command(sender, message)
        nil
       end
   
       @@bot.add_command(
        :syntax => 'user <username> <0-9>',
        :description => 'Retrieve last X twitter messages from given user',
        :regex => /^user\s+.+$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_user_command(sender, message)
        nil
       end

       @@bot.add_command(
        :syntax => 'search <query>',
        :description => 'Search and returns the 5 latest results',
        :regex => /^search\s+.+$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_search_command(sender, message)
        nil
       end

       @@bot.add_command(
        :syntax => 'replies',
        :description => 'Returns the 5 latest @replies from Twitter Search',
        :regex => /^replies$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_replies_command(sender, message)
        nil
       end

       @@bot.add_command(
        :syntax => 'new',
        :description => 'Delivers "unread" twitter messages',
        :regex => /^new$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_new_command(sender, message)
        nil
       end
       
       @@bot.add_command(
        :syntax => 'live <start|status|stop>',
        :description => 'Delivers new tweets as they come up. Requires start, status or stop instructions.',
        :regex => /^live\s+.+$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_live_command(sender, message)
        nil
       end       

       @@bot.add_command(
        :syntax => 'track <keyword>',
        :description => 'Delivers new tweets matching keyword search results as they come up.',
        :regex => /^track\s+.+$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_track_command(sender, message)
        nil
       end


       @@bot.add_command(
        :syntax => 'whois <username>',
        :description => 'Returns whois info for a given username',
        :regex => /^whois\s+.+$/,
        :is_public => false
       ) do |sender, message|
          execute_twitter_whois_command(sender, message)
        nil
       end       
       
       @@bot.add_command(
         :syntax => 'follow <username>',
         :description => 'Start following a given user.',
         :regex => /^follow\s+.+$/,
         :is_public => false
        ) do |sender, message|
           execute_twitter_follow_command(sender, message)
         nil
        end
        
        @@bot.add_command(
          :syntax => 'unfollow <username>',
          :description => 'Unfollow a given user.',
          :regex => /^unfollow\s+.+$/,
          :is_public => false
         ) do |sender, message|
            execute_twitter_unfollow_command(sender, message)
          nil
         end
       
        @@bot.add_command(
          :syntax      => 'bye',
          :description => 'Swiftly disconnects the bot',
          :regex       => /^bye$/,
          :is_public   => false
        ) do |sender, message|
            execute_bye_command(sender, message)
          nil
        end    
    
  end # load_commands
  
  
  def execute_bye_command(sender,message)
    deliver(sender, 'Bye bye.')
    @@bot.disconnect
    exit
  end  
  
  def execute_twitter_say_command(sender,message)
      deliver(sender, TwitterHub::Status.post(message))
  end
  
  def execute_twitter_me_command(sender,message)
      deliver(sender, TwitterHub::Client.me)
  end
  
  def execute_twitter_last_command(sender,message)
    if message =~ /[0-9]/
      limit = message
    else
      limit = 20 
    end
    deliver(sender, TwitterHub::Timeline.friends(limit))
  end
  
  def execute_twitter_all_command(sender,message)
    deliver(sender, TwitterHub::Timeline.friends(20))
  end
  
  def execute_twitter_trends_command(sender,message)
    deliver(sender, TwitterHub::Search.trends(sender))
  end

  def execute_twitter_dm_command(sender,message)
    deliver(sender, TwitterHub::Timeline.dm)
  end

  def execute_twitter_new_command(sender,message)
    deliver(sender, TwitterHub::Timeline.unread) # .unread is an exception, method names match command names as a rule.
  end
  
  def execute_twitter_live_command(sender,message)
    # Live Twitter message delivery happens inside a dedicated thread, so we make a different method call
    TwitterHub::Timeline.live(sender, message)
  end
  
  def execute_twitter_track_command(sender,message)
    # Live Twitter message delivery happens inside a dedicated thread, so we make a different method call
    TwitterHub::Search.track(sender, message)
  end
  
  def execute_twitter_whois_command(sender,message)
    
    user = message.split[0]  
    if user.match('@') != nil
      user = user.gsub('@', '')
    end # if
    deliver(sender, TwitterHub::User.whois(user))

  end # twitter_whois
  
  def execute_twitter_follow_command(sender,message)
    
    user = message.split[0]  
    if user.match('@') != nil
      user = user.gsub('@', '')
    end # if
    deliver(sender, TwitterHub::User.follow(user))

  end # twitter_follow
  
  def execute_twitter_unfollow_command(sender,message)
    
    user = message.split[0]  
    if user.match('@') != nil
      user = user.gsub('@', '')
    end # if
    deliver(sender, TwitterHub::User.unfollow(user))

  end # twitter_unfollow
  
  def execute_twitter_user_command(sender,message)
    
    user = message.split[0]
    limit = message.split[1] if message.split[1] != nil
    
    if user.match('@') != nil
      user = user.gsub('@', '')
    end
    
    if limit == nil
      limit = 20
    end
    
    deliver(sender, TwitterHub::Timeline.user(user, limit))
    
  end
  
  def execute_twitter_search_command(sender,message)
    deliver(sender, TwitterHub::Search.query(sender, message))
  end
  
  def execute_twitter_replies_command(sender,message)
    deliver(sender, TwitterHub::Search.replies)
  end
    
  # these methods are helpers
  def strip_html(str)
    # The messages the bot sends are not HTML and most IM clients create links when they detect the structure
    # So we strip HTML from the posts and let the IM clients work things out by themselves
    str.strip!
    tag_pat = %r,<(?:(?:/?)|(?:\s*)).*?>,
    @content = str.gsub(tag_pat, '')
  end
    
end # Bot 

class Helper
  
  def self.didwhen(old_time) # stolen from http://snippets.dzone.com/posts/show/5715
    val = Time.now - old_time
     if val < 10 then
       result = 'just a moment ago'
     elsif val < 40  then
       result = 'less than ' + (val * 1.5).to_i.to_s.slice(0,1) + '0 seconds ago'
     elsif val < 60 then
       result = 'less than a minute ago'
     elsif val < 60 * 1.3  then
       result = "1 minute ago"
     elsif val < 60 * 50  then
       result = "#{(val / 60).to_i} minutes ago"
     elsif val < 60  * 60  * 1.4 then
       result = 'about 1 hour ago'
     elsif val < 60  * 60 * (24 / 1.02) then
       result = "about #{(val / 60 / 60 * 1.02).to_i} hours ago"
     else
       result = old_time.strftime("%H:%M %p %B %d, %Y")
     end
    return "#{result}"
  end # self.didwhen

   def strip_html(str)
     # The messages the bot sends are not HTML and most IM clients create links when they detect the structure
     # So we strip HTML from the posts and let the IM clients work things out by themselves
     str.strip!
     tag_pat = %r,<(?:(?:/?)|(?:\s*)).*?>,
     return str.gsub(tag_pat, '')
   end
   
   def date_for(stamp)
     day = stamp.day
     month = stamp.month
     year = stamp.month
     return "#{day}/#{month}/#{year}"      
   end # date_for
  
end # Helper

end # Computer 

Computer::Bot.new # executes everything when this file is called by computerbot.rb. You will never create another Bot object :)
