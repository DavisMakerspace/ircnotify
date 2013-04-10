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

  def load_config config_path
    if not File.exists? config_path
      STDERR.puts "Error: Can't find config file #{config_path}"
      STDERR.puts "Either create it or specify another config file with: #{File.basename $0} [filename]"
      exit false
    end
    config_wrapper = "module Config\n%s\nend"
    module_eval config_wrapper % File.read(config_path), File.realpath(config_path), 0
    module_eval config_wrapper % File.read(File.join(File.dirname($0), "..", "share", "config.schema"))
  end

  def log msg, level=:info
    @bridge.log msg, level
  end
end
