module Bivouac
  if BOX == true
    a = []; (8 - "#{ENV['TAG']}".length).times { a << rand(16).to_s(16) }
    @@NICK = "#{ENV['TAG']}-#{a.join('')}"
  else
    @@NICK = ENV['TAG']
  end
  log "#{@@NICK}", :NICK
  NICKS = Redis::HashKey.new('NICKS')
  class Irc
    def initialize
    end
    def handle m
      Bot.new(m)
    end
  class Bot
    def initialize m
      @target, @payload, @join, @part = false, false, false, false
      @from = m.user.nick
      @text = m.message
      @chan = m.channel
      @words = @text.split(' ')
      if @chan
        log "#{@from} #{@chan} #{@words}", :IRC
      else
        case @words[0]
        when 'join'
          @target = @from
          @payload = "joining #{@words[1]}"
          @join = @words[1]
        when 'part'
          @target = @from
          @payload = "parting #{@words[1]}"
          @part = @words[1]
        when 'identify'
          
          else

        end
        
        log "#{@from} #{@words}", :BOT
      end
    end
    def join
      @join
    end
    def part
      @part
    end
    def target
      @target
    end
    def payload
      @payload
    end
  end
  end
  @@BOT = Irc.new
  @@IRC = Cinch::Bot.new do
    configure do |c|
      c.server   = ENV['CLUSTER']
      c.nick     = @@NICK
      c.channels = []
    end
    
    on :private do |m|
      b = @@BOT.handle m
      if b.target != false
        Target(b.target).send(b.payload)
      end
      if b.join != false
        @@BOT.join(b.join)
      end
      if b.part != false
        @@BOT.part(b.part)
      end
    end
  end
  def self.irc
    @@IRC
  end
end
