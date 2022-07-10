module Bivouac
  class Qrcode
    def initialize h
      @host = Bivouac[h]
    end
    def badge u, h={}
      @user = @host[u]
      opts = []; h.each_pair {|k,v| opts << "#{k}=#{v}" }
      m = ['Dt']; 14.times {m << rand(16).to_s(16)}
      n = "#{Time.now.utc.to_f}"
      @host.at["#{n}"] = m.join('')
      @host.dx[m.join('')] = n
      if "".length > 0
        return %[#{@host.url}/#{@host.qro[@user.id]}/#{@user.attr[:host]}?mark=#{m.join('')}&#{opts.join('&')}]
      else
        return %[#{@host.url}/#{@host.qro[@user.id]}?mark=#{m.join('')}&#{opts.join('&')}]
      end
    end
  end
  def self.qr h
    Qrcode.new(h)
  end
end
