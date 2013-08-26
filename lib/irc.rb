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
        c.messages_per_second = Config::IRC::MESG_PER_SECOND
      end
      @bot.on :private, //, self do |m, irc|
        irc.received m, m.params[1] if m.command == "PRIVMSG"
      end
      @bot.on :channel, //, self do |m, irc| irc.scan m end
    end
    def scan msg
      cmd = nil
      /^#{@bot.nick}(?:[:, ] *(?<cmd>.*)|$)/.match(msg.params[1]) {|m| cmd=m[:cmd]}
      /^#{Config::IRC::CMDPREFIX} *(?<cmd>.*)$/.match(msg.params[1]) {|m| cmd=m[:cmd]} if Config::IRC::CMDPREFIX
      self.received msg, cmd if cmd
    end
    def received msg, cmd
      @known_targets[msg.target.object_id] = msg.target
      @known_targets[msg.user.object_id] = msg.user
      @bridge.server_send msg.target, msg.user, cmd
    end
    def send src, msg, target_ids
      if target_ids
        targets = target_ids.map {|tid| @known_targets[tid] || @bot.user_list.find(tid) || @bot.channel_list.find(tid)}
        targets.keep_if {|t| t && (@bot.channels.index(t) || @bot.channels.index {|c| c.has_user?(t)})}
      else
        targets = @bot.channels
      end
      targets.uniq!
      targets.each do |t|
        maxlength = 510 - ': '.length - @bot.mask.to_s.length
        Array(msg).each do |m|
          @bot.irc.send ("PRIVMSG #{t.name} :" + (Config::IRC::MSGFORMAT % {src: src, msg: m}))[0,maxlength]
        end
      end
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
