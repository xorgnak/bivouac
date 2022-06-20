
module Bivouac
  ##
  # Bivouac: the host
  # user: the user
  # box: the zone, group, tag, crew, etc
  # @host = Bivouac[request.host || localhost][user][box]
  def self.[] k
    Host.new(k)
  end
  class Bank
    include Redis::Objects
    sorted_set :stat
    sorted_set :xfer
    def initialize
      @id = 'BANK'
    end
    def id; @id; end
    def give h={}
      self.stat.decrement(h[:type], h[:amt].to_i)
      User.new(h[:user]).stat.increment(h[:type], h[:amt].to_i)
    end
    def take h={}
      self.stat.increment(h[:type], h[:amt].to_i)
      User.new(h[:user]).stat.decrement(h[:type], h[:amt].to_i)
    end
    def swap h={}
      User.new(h[:user]).stat.decrement(h[:type][:from], h[:amt][:from])
      User.new(h[:user]).stat.increment(h[:type][:to], h[:amt][:to])
    end
  end
  BANK = Bank.new
  def self
    BANK
  end
  class Host
    include Redis::Objects
    # content
    hash_key :app
    #config
    hash_key :env
    # phone: id
    hash_key :ids
    # qr: id
    hash_key :qri
    # id: qr
    hash_key :entity
    # name: icon
    hash_key :badges
    def initialize i
      @id = i
    end
    def rnd u, *x
      i, q = [], []
      x.each {|e| i << e; q << e }
      (16 - i.length).times { i << rand(16).to_s(16); q << rand(16).to_s(16) }
      self.ids[i.join('')] = u
      self.qrs[q.join('')] = u
      n = User.new(u)
      n.attr[:id] = i.join('')
      n.attr[:qr] = q.join('')
    end
    def id; @id; end
    def tag t, *u
      
    end
    def lookup k
      User.new("#{self.ids[k]}@#{@id}")
    end
    def query k
      User.new("#{self.qrs[k]}@#{@id}")
    end
    def [] b
      User.new("#{b}@#{@id}")
    end
  end
  
  class Box
    include Redis::Objects
    # content
    hash_key :attr
    # handlers
    hash_key :app
    # config
    hash_key :env
    # id: user
    hash_key :job
    # members
    set :users
    # user: amt
    sorted_set :sponsoring
    # box: score 
    sorted_set :merit
    # user: clicks
    sorted_set :traffic
    # user: jobs
    sorted_set :work
    # user: amt
    sorted_set :credit
    # user: amt
    sorted_set :karma
    # badge: amt
    sorted_set :badges
    # badge: amt
    sorted_set :awards
    # commodity: amt
    sorted_set :stat
    # box 
    set :webs
    def initialize i
      @id = i
    end
    def id; @id; end
  end
  
  class User
    include Redis::Objects
    # content
    hash_key :attr
    # db
    hash_key :stor
    # cb
    hash_key :blok
    # cb desc
    hash_key :desc
    # job
    set :jobs
    # track: visits
    sorted_set :track
    # box: score
    sorted_set :merit
    # box: amt
    sorted_set :credit
    # box: amt
    sorted_set :karma
    # badge: amt
    sorted_set :badges
    # badge: amt
    sorted_set :awards
    # box: amt
    sorted_set :work
    # commodity: value
    sorted_set :stat
    # box
    set :boxes
    # iv
    set :ivs
    def initialize i
      @id = i
      if !self.attr.has_key? :pub
        c = cipher
        c.encrypt
        self.attr[:created] = Time.now.utc.to_i
        self.attr[:priv] = Base64.encode64(c.random_key)
        self.attr[:pub] = Base64.encode64(c.random_iv)
      end
    end
    def id; @id; end
    def [] u
      self.boxes << u
      uu = Box.new("#{@id}/#{u}")
      uu.users << @id
      return uu
    end
    def mk s, *k
      if k[0]
        b = k[0]
      else
        b = rnd
      end
      if k[1]
        self.desc[b] = k[1]
      end
      self.blok[b] = Base64.encode64(s)
      return b
    end
    def run k, h={}
      self.instance_eval %[@a = lambda {|params| #{Base64.decode64(self.blok[k])}; }]
      @a.call(h).to_s
    end
    def cipher
      OpenSSL::Cipher::AES.new(128,:CBC)
    end
    def rnd
      c = cipher
      c.encrypt
      c.key = Base64.decode64(self.attr[:priv])
      i = Digest::SHA1.hexdigest(Base64.encode64(c.random_iv))
      self.ivs << i
      return i
    end
    def encrypt data, *k
      if k[0]
        b = k[0]
      else
        b = rnd
      end
      self.stor[b] = Base64.encode64( data )
      return b
    end
    def decrypt b
      Base64.decode64(self.stor[b])
    end
  end
end

