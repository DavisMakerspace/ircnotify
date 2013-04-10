require 'cinch'

module IRCNotify
  class IRC
    def initialize bridge
      @bridge = bridge
      @known_targets = {}
      @bot = Cinch::Bot.new
      @bot.configure do |c|
        c.user = File.basename $0
        c.realname = c.user
        c.nick = Config::IRC::NICK
        c.server = Config::IRC::SERVER
        c.port = Config::IRC::PORT
        c.channels = Config::IRC::CHANNELS
      end
      @bot.on :connect, //, self do |m, irc| irc.connected end
      @bot.on :private, //, self do |m, irc| if m.command == "PRIVMSG" then irc.received m, m.message end end
      if Config::IRC::CMDPREFIX
        @bot.on :channel, /^#{Config::IRC::CMDPREFIX} *(.*)/, self do |m, irc, cmd| irc.received m, cmd end
      end
    end
    def connected
      @bot.on :channel, /^#{@bot.nick}(?:[:, ] *(.*)|$)/, self do |m, irc, cmd| irc.received m, cmd end
    end
    def received msg, cmd
      @known_targets[msg.target.object_id] = msg.target
      @known_targets[msg.user.object_id] = msg.user
      @bridge.server_send msg.target, msg.user, cmd
    end
    def send src, msg, target_ids
      if target_ids
        targets = target_ids.map {|tid| @known_targets[tid] || @bot.user_list.find(tid) || @bot.channel_list.find(tid)}
        targets.uniq!
        targets.keep_if {|t| t && (@bot.channels.index(t) || @bot.channels.index {|c| c.has_user?(t)})}
      else
        targets = @bot.channels
      end
      targets.each {|t| t.send (Config::IRC::MSGFORMAT % {src: src, msg: msg})}
    end
    def get_target id
      @known_targets[id]
    end
    def log msg, level
      @bot.log msg, level
    end
    def start
      @bot.start
    end
  end
end
