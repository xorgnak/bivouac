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
        if @params.has_key? :xfer
          if @params[:xfer][:amt].to_i > 0
            Bivouac.bank.give user: @target.id, type: @params[:xfer][:type], amt: @params[:xfer][:amt].to_i
          else
            Bivouac.bank.take user: @target.id, type: @params[:xfer][:type], amt: @params[:xfer][:amt].to_i
          end
        end
      end
      if @params.has_key? :do
        if @params[:do] == 'save'
          @params[:app].each_pair {|k,v| @host.app[k] = v }
          @params[:env].each_pair {|k,v| @host.env[k] = v }
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
