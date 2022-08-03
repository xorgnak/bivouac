log "STARTUP", :Startup
@hosts = {}
`hostname -I`.chomp.split(' ').each { |e| if "#{e}".length > 0; @hosts[e] = Bivouac[e]; end }
@admins = {}
Bivouac.hosts {|h| puts "host: #{h.id}"; @admins[h.id] = h.admin(ENV['ADMIN']) }
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
