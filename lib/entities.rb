
module Bivouac
  def self.classes
    [
      'visitor',
      'member',
      'influencer',
      'ambassador',
      'manager',
      'owner',
      'agent',
      'operator',
      'developer'
    ]
  end
  def self.icons
    [
      'check_box_outline_blank', # visitor
      'square',                  # member
      'radio_button_unchecked',  # influencer
      'radio_button_checked',    # ambassador
      'circle',                  # manager
      'blur_circular',           # owner
      'stars',                   # agent
      'star_border',             # operator
      'star'                     # developer
    ]
  end
  COLORS = ['lightgrey', 'darkgrey', 'yellow', 'orange', 'red', 'purple', 'blue', 'green', 'gold']
  # badge colors
  def self.fg
    ['darkgrey','lightgrey','purple', 'black', 'white', 'white', 'white', 'white', 'black']
  end
  def self.bg
    COLORS
  end
  # award colors
  def self.bd
    COLORS
  end
  def self.hosts &b
    if block_given?
      Redis::Set.new('HOSTS').members.each {|e| b.call(Host.new(e)) }
    else
      return Redis::Set.new('HOSTS').members.select {|e| !/\d+.\d+.\d+.\d+/.match(e) && !/.onion/.match(e) }
    end
  end
  ##
  # Bivouac: the host
  # user: the user
  # box: the zone, group, tag, crew, etc
  # @host = Bivouac[request.host || localhost][user][box]
  def self.[] k
      Redis::Set.new('HOSTS') << k
      Host.new(k)
  end
  class Bank
    include Redis::Objects
    sorted_set :stat
    sorted_set :acct
    def initialize i
      @id = i
    end
    def id; @id; end
    # { :user, :type, :amt }
    def give h={}
      self.stat.decrement(h[:type] || :credits, h[:amt] || 1)
      self.acct.increment(h[:user], h[:amt] || 1)
      User.new(h[:user]).stat.increment(h[:type] || :credits, h[:amt] || 1)
    end
    # { :user, :type, :amt }
    def take h={}
      self.stat.increment(h[:type] || :credits, h[:amt] || 1)
      self.acct.decrement(h[:user], h[:amt] || 1)
      User.new(h[:user]).stat.decrement(h[:type] || :credits, h[:amt] || 1)
    end
    # { user: user, type: { from: type, to: type } amt: { from: n, to: n }
    def swap h={}
      User.new(h[:user]).stat.decrement(h[:type][:from], h[:amt][:from] || 1)
      User.new(h[:user]).stat.increment(h[:type][:to], h[:amt][:to] || 1)
    end
  end
  class Vote
    include Redis::Objects
    hash_key :attr
    sorted_set :votes
    sorted_set :voters
    sorted_set :stat
    def initialize i
      @id = i
    end
    def id; @id; end
    def vote h={}
      case self.attr[:type]
      when 'election'
        if self.voters[h[:voter]] < 1
          self.voters.incr h[:voter]
          self.votes.incr h[:vote]
          self.stat.incr :total
        end
      else
        self.voters.incr h[:voter]
        self.votes.incr h[:vote]
        self.stat.incr :total
      end
    end
    def leaderboard
      w = self.votes.last
      h = { total: self.stat[:total], leader: w, score: self.votes[w], standings: standings }
      if self.attr[:type] != 'election'
        h[:assistant] = self.voters.last
        h[:votes] = self.voters[h[:assistant]]
        h[:assistants] = voting
      end
      return h
    end
    def rank u
      self.votes.rank u.to_sym
    end
    def voting
      self.voters.members(with_scores: true).to_h.sort_by {|k,v| v}.reverse.to_h
    end
    def standings
      self.votes.members(with_scores: true).to_h.sort_by {|k,v| v}.reverse.to_h
    end
  end

  class Map
    include Redis::Objects
    set :tracks
    set :waypoints
    sorted_set :track
    sorted_set :waypoint
    def initialize i
      @@MAP = @id = i
    end
    def << t
      self.track.incr(t)
      self.tracks << t
    end
    def [] k
      self.waypoint.incr(k)
      self.waypoints << k
      Waypoint.new(k)
    end
    def id; @id; end
  end
  
  class Track
    include Redis::Objects
    hash_key :attr
    sorted_set :stat

    list :path
    set :waypoints
    sorted_set :visits

    sorted_set :visitors
    sorted_set :contributors
    sorted_set :maintainers
    
    def initialize i
      @id = i
    end
    def id; @id; end
    def length
      self.path.length
    end
    def << waypoint
      if !self.path.include? waypoint
        self.path << waypoint
      end
      self.waypoints << waypoint
      self.visits.incr(waypoint)
    end
  end
 
  class Waypoint
    include Redis::Objects
    hash_key :attr
    sorted_set :stat
    sorted_set :track
    sorted_set :froms
    sorted_set :tos
    set :tracks
    def initialize i
      @id = i
    end
    def id; @id; end
    def length
      self.tracks.members.length
    end
    def [] t
      i = "#{t}:#{@id}"
      self.tracks << t
      self.track.incr(t)
      a = Track.new(t)
      a << @id
      return a
    end 
  end

  # MAP[host][waypoint][track]
  module MAP
    def self.[] k
      Map.new(k)
    end
  end
  class Host
    include Redis::Objects
    # content
    hash_key :app
    #config
    hash_key :env
    # phone: id
    hash_key :ids
    # id: phone
    hash_key :entity
    # qr: id
    hash_key :qri
    # id: qr
    hash_key :qro
    # name: icon
    hash_key :badges
    # time: mark
    hash_key :at
    # mark: time
    hash_key :dx
    
    # boxes
    set :boxes
    # contests
    set :votes
    set :contests
    set :users

    
    def initialize i
      @auths = Bivouac.auths(i)
      @id = i
      if /\d+.\d+.\d+.\d+/.match(i) || /.onion/.match(i) || i == 'localhost'
        @pre = 'http'
      else
        @pre = 'https'
      end
    end
    def badges
    {
      "support" => 'support',
      'explore' => 'explore',
      'shelter' => 'cabin',
      'medical' => 'local_hospital',
      'food' => 'restaurant',
      'clothing' => 'dry_cleaning',
      'flare' => 'flare',
      'vision' => 'flashlight_on',
      'ideas' => 'lightbulb',
    }.merge(Redis::HashKey.new("BADGES:#{@id}").all)
    end
    def auths
      @auths
    end
    def admin phone, &b
      if @auths.ids.has_key? phone
        u = @auths.ids[phone]
        uu = user u
        if block_given?
          return b.call(uu)
        else
          return uu
        end
      else
        return false
      end
    end
    def map
      MAP[@id]
    end
    def url
      return %[#{@pre}://#{@id}]
    end
    def id; @id; end
    def vote v
      self.votes << v
      Vote.new(v)
    end

    def contest v
      self.contests << v
      Vote.new(v)
    end
    
    def box_badge h={}
      Box.new(h[:box]).badges.incr(h[:badge])
    end
    def box_merit h={}
      Box.new(h[:box]).merit.incr(h[:badge])
    end
    def box_award h={}
      Box.new(h[:box]).awards.incr(h[:badge])
    end
    def user_badge h={}
      User.new(h[:user]).badges.incr(h[:badge])
    end
    def user_merit h={}
      User.new(h[:user]).merit.incr(h[:badge])
    end
    def user_award h={}
      User.new(h[:user]).awards.incr(h[:badge])
    end
    
    def contest
      now = Time.now.utc
      self.contests.members.each do |e|
        v = Vote.new(e)
        r = v.leaderboard
        if now.wday == 0
          box_badge box: r[:leader], badge: v.attr[:badge]
        end
        if now.mday == 0
          box_merit box: r[:leader], badge: v.attr[:badge]
        end
        if now.yday == 0
          box_award box: r[:leader], badge: v.attr[:badge]
        end
      end
    end
    def voting
      self.votes.members.each do |e|
        v = Vote.new(e)
        r = v.leaderboard
        if now.wday == 0
          user_badge user: r[:leader], badge: v.attr[:badge]
        end
        if now.mday == 0
          user_merit user: r[:leader], badge: v.attr[:badge]
        end
        if now.yday == 0
          user_award user: r[:leader], badge: v.attr[:badge]
        end
      end
    end
    # daily
    def daily
      self.boxes.members.each do |e|
        b = Box.new(e)
        if b.stat[:pay].to_i > 0
          b.users.members.each {|ee|
            u = User.new(ee)
            u.stat.incr(:credit, b.stat[:pay])
            b.stat.decr(:credit, b.stat[:pay])
            b.credit.incr(u.id, b.stat[:pay])
            u.credit.incr(b.id, b.stat[:pay])
          }
        end
      end
      voting
      contest
    end

    def [] b
      user b
    end
    def user b 
      if /.+@.+/.match(b)
        self.users << b
        User.new(b)
      else
        self.users << "#{b}@#{@id}"
        User.new("#{b}@#{@id}")
      end
    end
    def vs f, t
      @f, @t = User.new(f), User.new(t)
      @ff, @tt = {}, {}
      @f.stat.incr(:zapper)
      @t.stat.incr(:zapped)
      [@f, @t].each { |e| e.stat.incr(:xp); e.stat.incr(:encounters) }
      t = 0;
      if rand(@f.stat[:rank].to_i + @f.stat[:hp].to_i + 1) >= @t.stat[:rank].to_i + @t.stat[:ac].to_i
        log "#{@f.stat.members(with_scores: true)}", :ZAP
        @t.stat.incr(:gots)
        @f.stat.incr(:hits)
      end
      [@f, @t].each do |e|
        if "#{e.stat[:hits].to_i}".length > e.stat[:rank].to_i
          if e.stat[:rank].to_i < 8; e.stat.incr(:rank); end
        end
      end
      return nil
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
      ix = i.split('@')
      ih = ix[1].split('/')
      @host = ih[0]
      @user, @box = %[#{ix[0]}@#{ih[0]}], ih[1]
      @id = @box
      if !self.attr.has_key? :name
        self.attr[:name] = @box
        self.attr[:payee] = @user
        self.attr[:owner] = @user
        self.stat[:click] = 1
      end
    end
    def bank
      Bank.new(@id)
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
    # sponsor: amt
    sorted_set :sponsorship
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
    # visitors
    set :visitors
    def initialize i
      if "#{i}".length > 0
        @id = i
        x = i.split('@')
        @user, @host = x[0], Host.new(x[1])
        if !self.attr.has_key? :pub
          c = cipher
          c.encrypt
          self.attr[:host] = @host.id
          self.attr[:created] = Time.now.utc.to_i
          self.attr[:priv] = Base64.encode64(c.random_key)
          self.attr[:pub] = Base64.encode64(c.random_iv)
          x, q = [], []
          16.times { x << rand(16).to_s(16); q << rand(16).to_s(16) }
          @host.ids[@id] = x.join('')
          @host.entity[x.join('')] = @id
          @host.qri[q.join('')] = @id
          @host.qro[@id] = q.join('')
          self.attr[:id] = x.join('')
          self.attr[:qr] = q.join('')
        end
      else
        log "nil user", :Error
      end
    end
    def id; @id; end
    def [] u
      if "#{u}".length > 0
        @host.boxes << u
        self.boxes << u
        uu = Box.new("#{@id}/#{u}")
        uu.users << @id
        return uu
      end
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

