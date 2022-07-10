module Bivouac
  class Post
    def initialize request, params
      log "#{request.fullpath} #{params}", :Post
      @request, @params = request, params
      @path = request.host
      @json = {}
      if /\d+.\d+.\d+.\d+/.match(request.host) || request.host == 'localhost'
        @goto = "http://#{@path}"
      else
        @goto = "https://#{@path}"
      end
      @host = Bivouac[@path]
      if @params.has_key? :entity
        @entity = @host[@params[:entity]]
        
        if @params.has_key? :config
          @params[:config].each_pair {|k,v| @entity.attr[k] = v }
        end
        
        if @params.has_key? :box
          @entity[@params[:box]]
          @entity.attr[:box] = @params[:box]
          
          if @params.has_key? :admin
            @params[:admin].each_pair {|k,v| @box.attr[k] = v }
          end
        end
      end
      if @params.has_key? :target
        @target = @host[@params[:target]]
        
        if @params.has_key? :join
          @target[@params[:join]]
          @target.attr[:box] = @params[:join]
        end
        
        if @params.has_key? :magic
          @params[:magic].each_pair {|k,v| @target.attr[k] = v }
        end
        @goto = "#{goto}/?entity=#{@params[:entity]}"
      end
      
      if @params.has_key? :qri
        @target = @json[:target] = @host.qri[@params[:qri]]
        [:name, :title].each { |e| @json[e] = @host[@target].attr[e] }
        [:rank, :class].each { |e| @json[e] = @host[@target].stat[e].to_i }
      end
      
      if @params.has_key? :do
        if @params[:do] == 'save'
          @params[:app].each_pair {|k,v| @host.app[k] = v }
          @params[:env].each_pair {|k,v| @host.env[k] = v }
        elsif @params[:do] == 'zap'
          @goto = "#{@goto}/?entity=#{@params[:entity]}"
        end
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
