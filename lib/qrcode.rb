module Bivouac
  class Qrcode
    def initialize h
      if "#{ENV['MASK']}".length > 0
        @host = Bivouac[ENV['MASK']]
      elsif "#{Bivouac[h].env[:mask]}".length > 0
        @host = Bivouac[Bivouac[h].env[:mask]]
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
      vv = v.split('-')
      return %[#{@host.url}/#{q}?mark=#{vv[1]}&from=#{vv[2]}]
    end
    def app v, q, u
      vv = v.split('-')
      return %[#{@host.url}/#{q}/#{URI.encode(u)}?mark=#{vv[1]}&from=#{vv[2]}]
    end
    def point q
      %[#{@host.url}/#{q}]
    end
    def box q, b
      %[#{@host.url}/#{q}/#{URI.encode(b)}]
    end
  end
  def self.qr h
    Qrcode.new(h)
  end
end
