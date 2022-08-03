MQTT::Client.connect('vango.me') do |client|
  # If you pass a block to the get method, then it will loop
  client.get(`hostname`.chomp.upcase) do |topic,message|
    m = message.split(' ')
    if Redis::HashKey.new('CAMS').has_key?(m[0]) || Redis::HashKey.new('CAMS')[m[0]] != m[1] + ':80/'
      Redis::HashKey.new('CAMS')[m[0]] = m[1] + ':80/'
      `cd /home/pi/nomad && ./nomad.sh update && sudo reboot`
    end
  end
end
