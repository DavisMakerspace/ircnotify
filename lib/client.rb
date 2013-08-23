require 'json'
require 'etc'
require_relative 'urlshortener'

module IRCNotify
  class Client
    def initialize bridge, socket
      @bridge = bridge
      @socket = socket
      @peername = Etc.getpwuid(@socket.getpeereid[0]).name
      @name = @peername
      @commands = []
      @targets = nil
      @shorten_urls = Config::Server::URLSHORTEN
      IRCNotify.log "New connection #{@socket} by #{@peername}"
    end
    def start_read
      @socket.each do |line|
        line.chomp!
        IRCNotify.log "Client #{@socket} got: #{line}", :debug
        cmds = {}
        if line.start_with? "{"
          begin
            cmds = JSON::parse line
          rescue JSON::ParserError => error
            IRCNotify.log "Could not parse presumed JSON string: #{line}", :error
            IRCNotify.log "got error #{error}", :error
            cmds = {}
          end
        else
          cmds['send'] = line
        end
        handle_commands cmds
      end
      IRCNotify.log "Ending connection #{@socket}"
      @socket = nil
    end
    def send at, from, argv
      if @commands.include? argv[0]
        data = {
          at: at.object_id,
          at_name: at.name,
          from: from.object_id,
          from_name: from.name,
          argv: argv}
        @socket.write(data.to_json + "\r\n")
      end
    end
    def handle_commands cmds
      @name = cmds['set_name'].to_s if cmds['set_name']
      @commands = Array(cmds['set_commands']) if cmds['set_commands']
      @targets = Array(cmds['set_targets']) if cmds['set_targets']
      targets = cmds['targets'] ? Array(cmds['targets']) : @targets
      @shorten_urls = !!cmds['set_shorten_urls'] if cmds['set_shorten_urls']
      shorten_urls = cmds['shorten_urls'] ? !!cmds['shorten_urls'] : @shorten_urls
      if cmds['send']
        send = Array(cmds['send'])
        if shorten_urls then send.map! {|line| URLShortener::replace! line} end
        @bridge.irc_send @name, cmds['send'], targets
      end
    end
  end
end
