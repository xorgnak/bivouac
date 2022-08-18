require 'ruby_mud'
require 'redis-objects'
require 'erb'

WORLD = `hostname`.chomp.upcase!

class Mud
  include Redis::Objects
  hash_key :attr
  sorted_set :inv
  sorted_set :stat
  set :here
  value :pw
  value :owner
  def initialize i
    @id = i
  end  
  def id; @id; end
end

# Controllers define the action for a menu / sub-game. Eg: Login screen,
# main game, map screen, etc.. By default, the server will start new connections
# in MudServer::DefaultController.
class MudServer::DefaultController
  # on_start will always be called when the user enters a controller.
  # You don't need to use it, but it's there.
 
  def on_start
    @world = WORLD
    @mud = Mud.new(@world)
    id = ["#{@world}:"]; 6.times { id << rand(16).to_s(16) }
    @id = id.join('')
    @me = player(@id)
    Process.detach(
      fork {
        Redis.new.subscribe(@mud.id) { |on|
          on.message { |c, m|
            send_text m
          }
        }
      })
    File.read('/etc/logo').split("\n").each {|e| send_text e }
    void
    prompt
  end

  def player u
    Mud.new("#{@world}:#{u}")
  end

  def place p
    Mud.new("#{@world}/#{p}")
  end
  
  def login
    place(@here.id).here.delete(@id)
    u, p = params.split(' ')
    pw = player(u).pw.value
    if pw == nil
      player(u).pw.value = p
      send_text "login created."
      @id = u
      @me = player(@id)
      @me.attr[:goto] = true
      void
    elsif player(u).pw.value == p
      @id = u
      @me = player(@id)
      @me.attr[:goto] = true
      void
    else
      send_text "login failed."
    end
    prompt
  end

  def allowed_methods
    super + [
      'help',
      'login',
      'places',
      'void',
      'here',
      'goto',
      'do',
      'say',
      'own',
      'attr'
    ]
  end

  def send_error
    send_text "404"
  end
  
  def quit
    player(@id).attr[:goto] = false
    if @mud.attr.has_key? @id
      place(@mud.attr[@id]).here.delete(@id)
      @mud.attr.delete(@id)
    end
    place(@here.id).here.delete(@id)
    @session.connection.close
  end
  
  def say
    if @me.attr[:goto] == 'true'
      Redis.new.publish @world, "---> #{@id}@#{@here.id}: " + params
    else
      send_text "login to speak."
    end
    prompt
  end
  
  def help
    send_text "COMMANDS: #{allowed_methods}"
  end

  def void
    @me = player(@id)
    if @mud.attr.has_key? @id
      place(@mud.attr[@id]).here.delete(@id)
      @mud.attr.delete(@id)
    end
    @here = place('void')
    @here.here << @id
    #@me.owner.value = @id
  end

  def places
    @mud.here.members.each {|e| send_text "#{e}: #{place(e).attr[:desc]}" }
    prompt
  end
  
  def own
    if @me.attr[:goto] == 'true'
    pw = @here.pw.value
    if pw == params || pw == nil
      @here.owner.value = @id
      send_text "#{@here.id} owned."
    else
      send_text "failed."
    end
    else
      send_text "you must be logged in."
    end
    prompt
  end

  def attr
    if @here.id != 'void' && @here.owner.value == @id
      k, v = params.split(': ')
      @here.attr[k.to_sym] = v
      here
    else
      send_text "you don't own this."
    end
    prompt
  end
  
  def here
    send_text "@#{@id}: (#{@here.here.members.to_a.join(', ')})"
    ev = []
    @here.attr.all.each_pair { |k,v| if !/^on_/.match(k); send_text "#{k}: #{v}"; else; ev << k.gsub('on_', ''); end }
    send_text "DO: #{ev}"
  end

  def prompt
    send_text "#{@id}@#{@here.id}"
  end
  
  def do
    @params = params.split(' ')
    @verb = @params.shift
    send_text ERB.new(@here.attr["on_#{@verb}".to_sym]).result(binding)
    prompt
  end
  
  #Transfer people to a different menu / area using `transfer_to`
  def goto
    if @me.attr[:goto] == 'true'
    @mud.here << params
    @mud.attr[@id] = params
    place(@here.id).here.delete(@id)
    @here = place(params)
    @here.here << @id
    here
    send_text ERB.new(@here.attr["on_goto".to_sym] || '').result(binding)
    else
      send_text "You must be logged in to move."
    end
    prompt
  end
end


@server = MudServer.new '0.0.0.0', '4321'
@server.start

loop { gets }

