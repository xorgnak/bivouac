load 'exe/bivouac.rb'

puts "running in: #{Dir.pwd}"

def trap_exit!
Signal.trap('INT') { exit! }
Signal.trap('TERM') { exit! }
Signal.trap('EXIT') { exit! }
end

def exit!
  File.delete("#{Dir.pwd}/bivouac.lock")
  exit; exit;
end

if ENV['IRC'] == 'true'
  Process.detach( fork { trap_exit!; Bivouac.irc.start } )
end
  
if !File.exists? "#{Dir.pwd}/bivouac.lock"
  Process.detach( fork { trap_exit!; Bivouac::Httpd.run! } )
  File.open("#{Dir.pwd}/bivouac.lock", "w") {}
end

@admin = {}

Bivouac.hosts { |h| @admin[h.id] = h.admin(ENV['ADMIN']); h.admin(ENV['ADMIN']) { |u| u.stat[:class] = 8; u.stat[:credits] = 1000000 } }

begin
  Signal.trap('INT') { exit; }
  Pry.start
rescue => e
  log "#{e}", :ERROR
end

