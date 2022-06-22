module Bivouac
  class Qrcode
    def initialize h
      @host = Bivouac[h]
    end
    def badge u, h={}
      @user = @host[u]
      opts = []; h.each_pair {|k,v| opts << "#{k}=#{v}" }
      return %[#{@host.url}/#{@host.entity[u]}?at=#{Time.now.utc.to_i}&#{opts.join('&')}]
    end
  end
  def self.qr h
    Qrcode.new(h)
  end
end
