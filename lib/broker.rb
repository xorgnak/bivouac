module Bivouac
  class Tag
    def initialize pkt
      @pkt = pkt
    end
    def pkt
      @pkt
    end
  end
  class Broker
    def initialize
      @mqtt = PahoMqtt::Client.new({host: ENV['CLUSTER'], port: 1883, ssl: false})
      @mqtt.on_message do |message|
        if message.topic == ENV['TAG']
          @pkt = Tag.new(message)
          log "#{@pkt}", :TAG
        else
          log "#{message.topic}: #{message.payload}", :MQTT
        end
      end
      @mqtt.connect
      @mqtt.subscribe(["#", 2])
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
