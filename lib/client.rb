require 'json'
require 'etc'

module IRCNotify
  class Client
    def initialize bridge, socket
      @bridge = bridge
      @socket = socket
      @peername = Etc.getpwuid(@socket.getpeereid[0]).name
      @name = @peername
      @commands = []
      @targets = nil
      IRCNotify.log "New connection #{@socket} by #{@peername}"
    end
    def start_read
      @socket.each do |line|
        IRCNotify.log "Client #{@socket} got: #{line.strip}", :debug
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
          cmds['send'] = line.strip
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
      @targets = Array(cmds['set_targets']) if cmds['set_targets']
      targets = cmds['targets'] ? Array(cmds['targets']) : @targets
      @commands = Array(cmds['set_commands']) if cmds['set_commands']
      if cmds['send'] then @bridge.irc_send @name, cmds['send'], targets end
    end
  end
end
