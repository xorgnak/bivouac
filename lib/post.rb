module Bivouac
  class Post
    def initialize request, params
      log "#{request.fullpath} #{params}", :Post
      @request, @params = request, params
      @path = request.host
      @json = {}

      # interaction redirect path
      if /\d+.\d+.\d+.\d+/.match(request.host) || request.host == 'localhost' || /.onion/.match(request.host)
        @goto = "http://#{@path}"
      else
        @goto = "https://#{@path}"
      end
      @host = Bivouac[@path]
      
      # config interaction
      if @params.has_key? :entity
        @entity = @host[@params[:entity]]

        if "#{@params[:pic]}".length > 0
          @entity.pics << @params[:pic]
          if @entity.attr.has_key? :box
            @entity[@entity.attr[:box]].pics << @params[:pic]
          end
        end

        if @params.has_key? :config
          @params[:config].each_pair {|k,v| @entity.attr[k] = v; }
        end

        if "#{@entity.attr[:waypoint]}".length > 0
          #####
        end
        
        if @params.has_key?(:box) && "#{@params[:box]}".length > 0
          @box = @entity[@params[:box]]
          @entity.attr[:box] = @params[:box]
          
          if @params.has_key?(:admin)
            @params[:admin].each_pair {|k,v| if "#{v}".length > 0; @box.attr[k] = v; end }
          end
          if @params.has_key?(:boss)
            @params[:boss].each_pair {|k,v| if "#{v}".length > 0; @box.stat[k] = v.to_i; end }
          end
        end
        check @entity
      end
      # lookup interaction
      if "#{@params[:wand]}".length > 0
        @params[:target] = @host.admin(@params[:wand])
      end
      # scan interaction
      if @params.has_key? :target
        @target = @host[@params[:target]]

        if "#{@params[:pic]}".length > 0
          @target.pics << @params[:pic]
        end
        
        if @params.has_key? :join
          @target[@params[:join]]
          @target.attr[:box] = @params[:join]
        end
        
        if @params.has_key? :magic
          @params[:magic].each_pair {|k,v| if "#{v}".length > 0; @target.attr[k] = v; end }
        end
      
        if @params.has_key? :boost
          @params[:boost].each_pair {|k,v| @target.stat.incr(k) }
        end
        if @params.has_key? :touch
          @params[:touch].each_pair {|k,v| @target.badges.incr(k) }
        end
        if @params.has_key? :award
          @params[:award].each_pair {|k,v| @target.awards.incr(k) }
        end
        check @target
      end

      if /.+-.+-.+/.match(@params[:entity])
        u = @host[@host.qri[@params[:qri]]]
        @goto = "#{@goto}/#{@params[:qri]}/#{u.attr[:box]}"
      end

      # scan post return
      if @params.has_key? :qri
        @target = @json[:target] = @host.qri[@params[:qri]]
        [:name, :title].each { |e| @json[e] = @host[@target].attr[e] }
        [:rank, :class].each { |e| @json[e] = @host[@target].stat[e].to_i }
        if @params.has_key? :box
          @host.map[@target][@params[:box]].visitors.incr(@params[:entity])
        end
      end

      if @params.has_key?(:target) && @params[:target] != @entity.id 
        @tgt = @host.target(@params[:target])
        if @params.has_key? :tgt
          @params[:tgt].each_pair { |k,v| @tgt.attr[k] = v }
        end
        if @params.has_key? :entity
          @host[@params[:entity]].targets << @tgt.id
          @tgt.attr[:owner] = @entity.id
          if @params.has_key? :box
            @host[@params[:entity]][@params[:box]].targets << @tgt.id
            @tgt.attr[:goto] = %[#{@entity.attr[:qr]}/#{@params[:box]}?mark=#{@tgt.id}]
          else
            @tgt.attr[:goto] = %[#{@entity.attr[:qr]}?mark=#{@tgt.id}]
          end
        end
      end
      
      if @params.has_key? :do
        if @params[:do] == 'save'
          if @params.has_key? :app
            @params[:app].each_pair {|k,v| if "#{v}".length > 0; @host.app[k] = v; end }
          end
          if @params.has_key? :env
            @params[:env].each_pair {|k,v| if "#{v}".length > 0; @host.env[k] = v; end }
          end
        elsif @params[:do] == 'zap' || @params[:do] == 'update'
          @goto = "#{@goto}/?entity=#{@params[:entity]}"
        elsif @params[:do] == 'app'
          u = @host[@host.qri[@params[:qri]]]
          @goto = "#{@goto}/#{@params[:qri]}/#{@params[:box] || u.attr[:box]}"
        elsif @params[:do] == 'target'
          @goto = "#{@goto}/t?target=#{@params[:target]}"
        end
      end
    end
    def check u
      if u.boxes.members.length > 0 && u.stat[:class].to_i < 1
        u.stat[:class] = 1
      end
      if u.stat[:xp] >= 10 && u.stat[:class] < 2
        u.stat[:class] = 2
      end
      if u.stat[:karma] >= 100 && u.stat[:class] < 3
        u.stat[:class] = 3
      end
    end
    def path
      @path
    end
    def goto
      @goto
    end
    def json
      JSON.generate(@json)
    end
  end
end
