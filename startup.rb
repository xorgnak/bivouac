log "STARTUP", :Startup

@host = Bivouac['192.168.146.52']
@usr = @host['481588e5f4a8ad72@192.168.60.52']
def doit *n
  if n[0]
    t = n[0]
  else
    t = 0
  end
  Bivouac.badges.keys.each {|e| @usr.badges[e] = t }
end
#@you = @host['you']
#@here = @usr['here']
#@there = @usr['there']
#@zap = @you['not here']
#@host.vs @usr.id, @you.id

#@vote = @host.vote('test vote')
#@vote.vote({voter: @usr.id, vote: @usr.id })

#100.times { |t| @vote.vote voter: "usr#{rand(10)}", vote: [:a, :b, :c, :d].sample }
