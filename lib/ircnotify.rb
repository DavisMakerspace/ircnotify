require_relative 'bridge'

module IRCNotify
  extend self

  NAME = File.basename $0
  VERSION = %x{cd #{File.dirname $0} && git describe --dirty=-modified}.strip
  HOST = Socket.gethostbyname(Socket.gethostname).first

  def run
    @bridge = Bridge.new
    @bridge.start
  end

  module Config
    extend self
    def load config_path
      if not File.exists? config_path
        STDERR.puts "Error: Can't find config file #{config_path}"
        STDERR.puts "Either create it or specify another config file with: #{File.basename $0} [filename]"
        exit false
      end
      module_eval File.read(config_path), File.realpath(config_path)
      module_eval File.read(File.join(File.dirname($0), "..", "share", "config.schema"))
    end
  end

  def log msg, level=:info
    @bridge.log msg, level
  end
end
