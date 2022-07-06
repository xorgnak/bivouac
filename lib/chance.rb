module Bivouac
 module Chance
    def self.card h={}
      @suit = { '&heartsuit;' => 'red', '&diamondsuit;' => 'red', '&spadesuit;' => 'black', '&clubsuit;' => 'black' }
      @card = {}
      [:A, :K, :Q, :J].each {|e| @card[e] = 10 }
      (2..10).each {|e| @card[e] = e }
      t, h[:result] = 0, []
      (h[:times] || 1).times {
        c = @card.keys.sample
        s = @suit.keys.sample
        t += @card[c]
        d = %[#{c}#{s}]
        h[:result] << { color: @suit[s], value: @card[c], card: c, suit: s, text: d }
      }
      h[:value] = t
      return h
    end
    def self.roll h={}
      t, h[:result] = 0, []
      (h[:times] || 1).times {
        r = rand(h[:sides] || 6)
        t += r
        h[:result] << { value: r, text: r }
      }
      h[:value] = t
      return h
    end
  end
  def self.chance
    Chance
  end
end
