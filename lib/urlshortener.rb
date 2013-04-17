require 'json'
require 'net/http'

module IRCNotify
  module URLShortener
    extend self

    ISGD_BASE_URI = URI::HTTP::build host:'is.gd', path:'/create.php'
    @http = Net::HTTP.new ISGD_BASE_URI.host
    @urldb = {}

    def shorten url
      if url.length < Config::Server::URLMAXLEN
        url
      elsif short = @urldb[url]
        short
      else
        isgd_uri = ISGD_BASE_URI
        isgd_uri.query = URI.encode_www_form format:'json', url:url
        http_response = @http.request Net::HTTP::Get.new isgd_uri
        if (http_response.is_a? Net::HTTPSuccess) && short = (JSON.parse http_response.body)['shorturl']
          @urldb[url] = short
        else
          url
        end
      end
    end

  end
end
