require 'socket'
require 'shellwords'
require_relative 'client'

module IRCNotify
  class Server
    def initialize bridge
      @bridge = bridge
      @unix_server = nil
      @clients = []
      @mutex = Mutex.new
    end
    def start
      return if @unix_server
      begin
        @unix_server = UNIXServer.new Config::Server::PATH
        File.chmod(Config::Server::MODE, Config::Server::PATH) if Config::Server::MODE
        while socket = @unix_server.accept do
          Thread.new(Client.new(@bridge,socket)) do |client|
            IRCNotify.log "Adding client #{client}"
            @mutex.synchronize { @clients << client }
            begin
              client.start_read
            rescue => error
              IRCNotify.log "Client error: #{error}", :error
            end
            IRCNotify.log "Removing client #{client}"
            @mutex.synchronize { @clients.delete client }
          end
        end
      ensure
        File.delete Config::Server::PATH
        @unix_server = nil
      end
    end
    def stop
      return if !@unix_server
      @unix_server.shutdown
    end
    def send at, from, cmd
      begin
        argv = cmd.shellsplit
      rescue ArgumentError => error
        @bridge.irc_send NAME, "#{error}"
      else
        if argv.size > 0
          @mutex.synchronize{ @clients.each{|c|c.send(at,from,argv)} }
        else
          @bridge.irc_send NAME, "#{VERSION} listening on #{HOST}:#{@unix_server.path}"
        end
      end
    end
  end
end
