module Bivouac
  class Qrcode
    def initialize h
      if "#{ENV['MASK']}".length > 0
        @host = Bivouac[ENV['MASK']]
      else
        @host = Bivouac[h]
      end
    end
    def badge u, h={}
      @user = @host[u]
      opts = []; h.each_pair {|k,v| opts << "#{k}=#{v}" }
      m = ['Dt']; 14.times {m << rand(16).to_s(16)}
      n = "#{Time.now.utc.to_f}"
      @host.at["#{n}"] = m.join('')
      @host.dx[m.join('')] = n
      if "#{ENV['MASK']}".length > 0
        return %[#{@host.url}/#{ENV['ID']}/#{URI.encode(ENV['BOX'])}?mark=#{m.join('')}&#{opts.join('&')}]
      else
        if "#{@user.attr[:box]}".length > 0
          return %[#{@host.url}/#{@host.qro[@user.id]}/#{@user.attr[:box]}?mark=#{m.join('')}&#{opts.join('&')}]
        else
          return %[#{@host.url}/#{@host.qro[@user.id]}?mark=#{m.join('')}&#{opts.join('&')}]
        end
      end
    end
    def entity v, q
      return %[#{@host.url}/#{q}?v=#{v}]
    end
    def app v, q, u
      return %[#{@host.url}/#{q}/#{u}?v=#{v}]
    end
  end
  def self.qr h
    Qrcode.new(h)
  end
end
