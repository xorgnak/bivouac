if "#{ENV['DOMAINS']}".length > 0
  BOX = false
else
  BOX = true
end
def log s, *t
  Redis.new.publish("#{t[0] || 'LOG'}", s)
end
module Bivouac
  def self.methods
    [ :broker ]
  end
end
load 'lib/require.rb'
load 'lib/broker.rb'
load 'lib/entities.rb'
load 'lib/input.rb'
load 'lib/qrcode.rb'
load 'lib/httpd.rb'
load 'lib/irc.rb'

# BIVOUAC
# A domain hosted on one or more bivouac instances is called a cluster.
# A local bivouac instance may use a domain cluster for remote device management.
# Iot devices will announce themselves on the cluster.  The local instance will
# then handle the device. 
# === Overview
#     (CLUSTER)              (TAG)              (DEV)
# [bivouac cluster] <-> [local bivouac] <-> [iot devices]
#         |
#         V
#      [https] <- a configurable webapp with lots of options.
#         |
#         V
#      [track] <- a set of locations with instructions.
#         |
#         V
#       [log]  <- the record of tracks on the cluster.
# === Options
# 1. users? -> profiles 
# 2. merit? -> badges, levels, contests, sponsorship

