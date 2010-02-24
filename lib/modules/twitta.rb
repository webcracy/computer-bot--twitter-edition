# sudo gem install twitter4r
# http://twitter4r.rubyforge.org

require 'rubygems'
require 'twitter'
require 'open-uri'
require 'yaml/store'

config = YAML::load(File.open(File.dirname(__FILE__) + "/../config/#{ENV_SET}.yml"))

Twitter_username = config['twitter']['username']
Twitter_password = config['twitter']['password']

Twitter::Client.configure do |conf|
   # We can set Twitter4R to use <tt>:ssl</tt> or <tt>:http</tt> to connect to the Twitter API.
   # Defaults to <tt>:ssl</tt>
   conf.protocol = :ssl

   # We can set Twitter4R to use another host name (perhaps for internal
   # testing purposes).
   # Defaults to 'twitter.com'
   conf.host = config['twitter']['host'] || 'twitter.com'

   # We can set Twitter4R to use another port (also for internal
   # testing purposes).
   # Defaults to 443
   conf.port = config['twitter']['port'] || 443

   # We can set Twitter4R to use another path (for Twitter compatible APIs)
   if config['twitter']['path']
      if conf.respond_to?:path
         conf.path = config['twitter']['path']
      else
         raise 'This version of Twitter4R does not support different API paths.'
      end
   end

   # We can set proxy information for Twitter4R
   # By default all following values are set to <tt>nil</tt>.
   #conf.proxy_host = 'myproxy.host'
   #conf.proxy_port = 8080
   #conf.proxy_user = 'myuser'
   #conf.proxy_pass = 'mypass'

   # We can also change the User-Agent and X-Twitter-Client* HTTP headers
   conf.user_agent = 'Computerbot'
   conf.application_name = 'Computerbot'
   conf.application_version = 'v1'
   conf.application_url = 'http://webcracy.org'

   # Twitter (not Twitter4R) will have to setup a source ID for your application to get it
   # recognized by the web interface according to your preferences.
   # To see more information how t
   # o go about doing this, please referen to the following thread:
   # http://groups.google.com/group/twitter4r-users/browse_thread/thread/c655457fdb127032
   #conf.source = "your-source-id-that-twitter-recognizes"

end


module TwitterHub
  
  class Persistence
    
    def self.load(id_type)
      status_id = ''
      YAML::Store.new(File.dirname(__FILE__) + '/../store/twitter_store.yml').transaction do |store|
        status_id = store[id_type]
      end
      return status_id
    end # self.load
    
    def self.store(id_type, status_id)
      YAML::Store.new(File.dirname(__FILE__) + '/../store/twitter_store.yml').transaction do |store|
        store[id_type] = status_id
      end
    end # self.store
    
  end # Persistence
  
  class Client
    
    def self.connect
      return Twitter::Client.new(:login => Twitter_username, :password => Twitter_password)
    end # self.connect
    
    def self.me
      return "You're logged in as: #{Twitter_username}"
    end # self.me
    
  end # Client
  
  class Status
    
    def self.post(status)
      
      begin
        twitter = TwitterHub::Client.connect
        rescue 
          return "I couldn't reach Twitter, sorry. Please try again."
      end # begin
      
      if twitter
        begin
          posted_status = twitter.status(:post, status)
        rescue => re
          "I couldn't post to Twitter, sorry. Please try again. Error was #{re.to_s}."
        end # begin        
        if posted_status 
          return "Status updated: http://twitter.com/#{Twitter_username}/statuses/#{posted_status.id}"
        else 
          return "For no valid reason, I can't be sure this worked. You should check it out: http://twitter.com. Maybe it's a whale."
        end # if posted_status
        
      end # if twitter
      
    end # self.post  
    
  end # Status
  
  class Timeline
    
    def self.unread # exception: called by the twitter.+new+ command. commands match methods as a rule
      twitter = TwitterHub::Client.connect
      
      if TwitterHub::Persistence.load('unread')
        timeline = twitter.timeline_for(:friends, :since_id => TwitterHub::Persistence.load('unread'))
      else
        timeline = twitter.timeline_for(:friends)
        store = TwitterHub::Persistence.store('unread', timeline.first.id)
        return timeline
      end # TwitterHub::Persistence.load
      
      if timeline.length > 0
        store = TwitterHub::Persistence.store('unread', timeline.first.id)
        messages = Array.new
        timeline.each do |status|
          message = TwitterHub::Helper.format_status(status)
          messages << message
        end
        return messages
      else
        return 'No new messages since your last check'
      end
    end # self.unread
    
    def self.live(sender, order)
      if order == 'start'
        @twitterhub_client = TwitterHub::Client.connect
        @twitter_live_thread = Thread.new do 
          Computer::Bot.deliver(sender, "Live Twitter feed started at #{Time.now.to_s}")
          loop do
            timeline = @twitterhub_client.timeline_for(:friends, :since_id => TwitterHub::Persistence.load('unread'))
            if timeline.length > 0 # and timeline.length < 11 <= this could be a solution for backlog. 
              # Computer::Bot.deliver(sender, "A delivery at #{Time.now.to_s}")
              store = TwitterHub::Persistence.store('unread', timeline.first.id)
              messages = Array.new
              timeline.each do |status|
                message = TwitterHub::Helper.format_status(status)
                messages << message
              end
              Computer::Bot.deliver(sender, messages)
            end # if
            sleep 60
          end # loop
        end # Thread.new
      elsif order == 'status'
        if @twitter_live_thread and @twitter_live_thread.alive? != false
          Computer::Bot.deliver(sender, 'The Live feed is running and seems OK. Tell your friends to tweet!')
        else
          Computer::Bot.deliver(sender, 'Live Twitter feed not running.')
        end # if
      elsif order == 'stop'
        @twitter_live_thread.exit
        Computer::Bot.deliver(sender, 'Live Twitter feed stopped.')
      end # if
      
    end # self.live
    
    def self.friends(limit)      
      twitter = TwitterHub::Client.connect
      timeline = twitter.timeline_for(:friends, :count => limit)
      messages = Array.new
      timeline.each do |status|
        message = TwitterHub::Helper.format_status(status)
        messages << message
      end      
      return messages      
    end # self.friends
    
    def self.mentions
      twitter = TwitterHub::Client.connect
      timeline = twitter.timeline_for(:mentions)
      timeline.map do |status|
        TwitterHub::Helper.format_status(status)
      end
    end
    
    def self.dm
      twitter = TwitterHub::Client.connect
      dms = twitter.messages(:received)
      messages = Array.new
      dms[0..4].each do |dm|
        dm = TwitterHub::Helper.format_dm(dm)
        messages << dm
      end
      return messages
    end # self.dm
    
    def self.user(user, limit)
      twitter = TwitterHub::Client.connect
      begin 
        user_test = twitter.user(user)
        rescue Twitter::RESTError => re
      end # begin
      if user_test != nil
        timeline = twitter.timeline_for(:user, :id => user)
        if limit != nil
          timeline = timeline[(0..(limit.to_i - 1))]
        end # if limit
        messages = Array.new
        timeline.each do |status|
          message = TwitterHub::Helper.format_status(status)
          messages << message
        end # timeline.each
        return messages
      else
        return "User #{user} has a private profile or does not exist."
      end # if user_test
    end # self.user
    
  end # Timeline
  
  class Search
    
    def self.query(sender, query)
      original_query = query
      query = query.gsub(' ', '+')
      query = query.gsub('#', '%23')
      query = query.gsub('@', '%40')
      begin
        search = JSON.load open("http://search.twitter.com/search.json?q=#{query}")
      rescue 
        return "I couldn't reach the server. Please try again."
      end
      if search and search['results'].length > 0
        messages = Array.new
        search['results'][0..4].each do |status|
          message = TwitterHub::Helper.format_search_status_json(status)
          messages << message
        end
        return messages
      else
        return "No results found for query: #{original_query}"
      end # if search.entries...
    end # self.query
    
    def self.trends(sender)
      begin
        search = JSON.load open("http://search.twitter.com/trends.json")
        rescue
        return "I couldn't fetch the trends, sorry. Try again later."
      end # begin
      
      if search and search['trends'].length > 0
        trends = Array.new
        search['trends'].each { |trend| trends << trend['name'] }
        return trends.join(', ')
      else 
        return "I didn't find any trends... sorry about that. Try again later."
      end # if search
                
    end # self.trends
      
      
    def self.track(sender, query)
    
      if query != 'status' and query != 'stop'
              
        targets = Persistence.load('track')
        if targets.is_a?(Array)
          words = Array.new
          targets.each { |target| words << target[:word] }
          if words.include?(query)
            targets.each do |target|
              if target[:word] == query
                target[:on] = true
              end # if target[:word]
            end # targets.each
            store = Persistence.store('track', targets)
          else
            if query != 'start'
              new_target = {:word => query, :on => true, :max_id => '' }
              targets << new_target
              store = Persistence.store('track', targets)
              Helper.deliver_new_track_target_results(sender, query)
            end
          end # words.include?      
        else # if targets.is_a?(Array)
          if query != 'start'
            targets = Array.new
            new_target = {:word => query, :on => true, :max_id => ''}
            targets << new_target
            store = Persistence.store('track', targets)     
            Helper.deliver_new_track_target_results(sender, query)       
          end # if query != 'start'
        end # if target_list.is_a?(Array)    

        if not @track_live_thread or @track_live_thread.alive? == false
          @track_live_thread = Thread.new do 
            loop do
              targets = Persistence.load('track')  
              targets.each do |target| #if targets.is_a?(Array)
                if target[:on] == true
                  word = target[:word]
                  max_id = target[:max_id]
                  keyword = Helper.format_query(word)
                  begin
                    search = JSON.load open("http://search.twitter.com/search.json?q='#{keyword}'&since_id='#{max_id}'")
                  rescue
                  end # begin
                    target[:max_id] = search['max_id']
                    messages = Array.new
                    search['results'].each do |status|
                      if status['id'].to_i > max_id.to_i
                        message = Helper.format_search_status_json(status)
                        messages << message
                      end # if status['id']
                    end # search['results'].each        
                end # if target[:on] == true
                Computer::Bot.deliver(sender, messages)          
              end # targets.each    
              store = Persistence.store('track', targets)             
              sleep 60
            end # loop
          end # Thread.new        
        end # if not @track_live_thread 
      
      elsif query == 'status'
        targets = Persistence.load('track')
        words = Array.new
        targets.each do |target| 
          if target[:on] == true
            words << target[:word]
          end # if target[:on]
        end # targets.each
        messages = Array.new
        messages << "Tracking: #{words.join(', ')}"
        if @track_live_thread and @track_live_thread.alive? == true
          messages << "The track live feed is running."
        else
          messages << "The track live feed is *not* running."
        end # if @track_live_thread 
        
        Computer::Bot.deliver(sender, messages)
        
      elsif query == 'stop'
        
        if @track_live_thread and @track_live_thread.alive? == true
          kill = @track_live_thread.exit
          if kill 
            Computer::Bot.deliver(sender, 'Track live feed stopped.')
          else
            Computer::Bot.deliver(sender, "Sorry, I couldn't stop the track live feed. You should restart the bot...")
          end # if kill
        end # if @track_live_thread
          
      end # if query != 'status'
    
    end # self.track
    
    def self.untrack(sender, query)
      
      targets = Persistence.load('track')
      if targets.is_a?(Array)
        words = Array.new
        targets.each { |target| words << target[:word] }
        if words.include?(query)
          targets.each do |target|
            if target[:word] == query
              target[:on] = false
            end # if target[:word]
          end # targets.each
          store = Persistence.store('track', targets)
          return "#{query} has been removed from the list."
        else
          return "I don't think you were tracking #{query}."
        end # if words.include?
      end # if targets.is_a?(Array)
    end #self.untrack
              
    
    def self.replies
      user = Twitter_username
      begin
      search = JSON.load open("http://search.twitter.com/search.json?q='%40#{user}'")
      rescue
        return "I couldn't reach the server, sorry. Please try again."
      end # begin
      if search['results'].length > 0
        messages = Array.new
        search['results'][0..4].each do |status|
          message = TwitterHub::Helper.format_search_status_json(status)
          messages << message
        end # search.entries.each
        return messages 
      else
        return "Sorry, I found no replies to @#{user}."
      end # if search.entries.length
    end # self.replies
    
  end # Search
  
  class User
    
    def self.whois(username)      
      twitter = TwitterHub::Client.connect
      begin
        user = twitter.user(username)
        rescue Twitter::RESTError => re 
      end
      if user != nil
        messages = Array.new
        head = "Who is " + username + "? http://twitter.com/#{username}"
        messages << head
        intro = "#{user.name} tweets from #{user.location}. Web: #{user.url}"
        messages << intro
        bio = "Bio: #{user.description}"
        messages << bio
        tweet = twitter.timeline_for(:user, :id => username)[0].text
        latest_tweet = "Last tweet from #{username}: #{tweet}"
        messages << latest_tweet
        follow = "Use 'twitter.(un)follow #{username}' or 'twitter.user #{username} X' to retrieve X latest msgs."
        messages << follow
        return messages
      else 
        return "User '#{username}' was not found. Please try again."
      end # if
    end # self.whois
    
    def self.follow(username)
      twitter = TwitterHub::Client.connect
      friend = twitter.user(username)
      begin 
        twitter.friend(:add, friend.id) 
        rescue Twitter::RESTError => re 
          case re.code
            when "403" 
              return "You're already following #{username}, so nothing happened just now."
            else  
              return 'Whooops, a weird thing happened. Please retry. ' + re.to_s
          end # case
      end # begin
      return "You're now following #{username} -- http://twitter.com/#{username}"      
    end # self.follow
    
    def self.unfollow(username)
      twitter = TwitterHub::Client.connect
      friend = twitter.user(username)
      begin 
        twitter.friend(:remove, friend.id) 
        rescue Twitter::RESTError => re 
          case re.code
            when "403" 
              return "You weren't following #{username}, so nothing new happened."
            else  
              return 'Whooops, a weird thing happened. Please retry. ' + re.to_s
          end # case
      end # begin
      return "You won't receive #{username}'s updates anymore."      
    end # self.unfollow
    
  end # User
  
  class Helper
    
    def self.format_status(status)
      return status.user.screen_name.to_s + ': ' + status.text.to_s + ' -- ' + TwitterHub::Helper.didwhen(status.created_at) + '.'
    end # self.format_status
    
    def self.format_dm(status)
      return status.sender.screen_name.to_s + ': ' + status.text.to_s + ' -- ' + TwitterHub::Helper.didwhen(status.created_at) + '.'
    end # self.format_dm
      
    def self.format_search_status_rss(status)
      return status.author.split[0] + ': ' + status.title + ' -- ' + TwitterHub::Helper.didwhen(status.updated) + '.'
    end # self.format_search_status_rss
    
    def self.format_search_status_json(status)
      return status['from_user'] + ': ' + status['text'] + ' -- ' + TwitterHub::Helper.didwhen(Time.parse(status['created_at'])) + '.'
    end # self.format_search_status_json
    
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
    
    def self.format_query(query)
      query = query.gsub(' ', '+')
      query = query.gsub('#', '%23')
      query = query.gsub('@', '%40')
      return query
    end
    
    
    def self.deliver_new_track_target_results(sender, target)
      
      query = TwitterHub::Helper.format_query(target)
      begin
        initial_search = JSON.load open("http://search.twitter.com/search.json?q='#{query}'")
      rescue
         Computer::Bot.deliver(sender, "I couldn't reach Twitter to fetch '#{query}' .")
      end # begin 
      if initial_search['results'].length > 0
        targets = Persistence.load('track')
        if targets.is_a?(Array)
          targets.each do |word|
            if word[:word] == target
              word[:max_id] = initial_search['max_id']
            end # if targets
          end # if targets.each
          Persistence.store('track', targets)
        end # if targets
        Computer::Bot.deliver(sender, "These were the latest 2 tweets before you started tracking '#{query}': ")
        messages = Array.new
        initial_search['results'][0..1].each do |status|
          message = TwitterHub::Helper.format_search_status_json(status)
          messages << message
        end # initial_search['results'].each 
        Computer::Bot.deliver(sender, messages)
      else 
        Computer::Bot.deliver(sender, "No previous results were found for your query '#{original_query}'. Tracking is enabled.")
      end # if initial_search['results']
    end # self.new_track_target
    
  end # Helper

end # TwitterHub
