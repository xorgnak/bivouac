module Bivouac
  if "#{ENV['TAG']}".length > 0
    TAG = ENV['TAG']
  else
    TAG = `hostname`.chomp.upcase
  end
  def self.tag
    TAG
  end
  if "#{ENV['CLUSTER']}".length > 0
    CLUSTER = ENV['CLUSTER']
  else
    CLUSTER = 'localhost'
  end
  def self.cluster
    CLUSTER
  end
  DEVS = Redis::Set.new('DEVS')
  DEVICES = Redis::HashKey.new('DEVICES')
  class Dev
    include Redis::Objects
    hash_key :ip
    def initialize i
      @id = i
    end
    def id; @id; end
  end
  def self.devs
    DEVS
  end
  def self.dev d
    DEVS << d
    Dev.new(d)
  end
  class Tag
    def initialize pkt
      m = pkt.split(' ')
      if /.+-.{6}/.match(m[0])
        d = Bivouac.dev(m[0])
        d.ip[:v4] = "#{m[1]}";
        d.ip[:v6] = "#{m[2]}";
        DEVICES[d.id] = "location /#{d.id} { proxy_pass http://#{d.ip[:v4]}:80/; }"
        @type = 'DEV'
      else
        @type = 'GEN'
      end
    end
    def type
      @type
    end
  end
  class Broker
    def initialize
      @mqtt = PahoMqtt::Client.new({host: CLUSTER, port: 1883, ssl: false})
      @mqtt.on_message do |message|
        @pkt = Tag.new(message.payload)
        log "#{@pkt.type}", :TAG
      end
      @mqtt.connect
      @mqtt.subscribe([TAG, 2])
    end
    def publish h={}
      @mqtt.publish(h[:topic], h[:payload], h[:retain] || false, h[:qos] || 1)
    end
  end
  @@BROKER = Broker.new
  def self.broker
    @@BROKER
  end
end
