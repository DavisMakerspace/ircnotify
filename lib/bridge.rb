require_relative 'server'
require_relative 'irc'

module IRCNotify
  class Bridge
    def initialize
      @server = Server.new self
      @irc = IRC.new self
    end
    def server_send at, from, cmd
      @server.send at, from, cmd
    end
    def irc_send src, msg, target_ids=nil
      @irc.send src, msg, target_ids
    end
    def start
      threads = []
      threads << Thread.new {@server.start}
      threads << Thread.new {@irc.start}
      threads.each {|t| t.join}
    end
    def log msg, level
      @irc.log msg, level
    end
  end
end
