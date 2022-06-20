module Bivouac
  class Post
    def initialize path, request, params
      log "#{request.fullpath} #{params}", :Post
      @request, @params = request, params
      @host = Host.new(@path)
      if /\d+.\d+.\d+.\d+/.match(request.host) || request.host == 'localhost'
        @path = 'localhost'
        @goto = "http://#{@path}"
      else
        @path = request.host
        @goto = "https://#{@path}"
      end
      if @params.has_key? :entity
        @entity = @host[@params[:entity]]
      end
      if @params.has_key? :box
        @box = @host[@entity][@params[:box]]
      end
      if @params.has_key? :target
        @target = @host[@params[:target]]
      end
      
      if @params.has_key? :on
        @host.env[@params[:on].to_sym] = true
        @goto = @request.fullpath
      end
      if @params.has_key? :off
        @host.env[@params[:off].to_sym] = false
        @goto = @request.fullpath
      end
      
      if @params.has_key? :config
        @params[:config].each_pair {|k,v| @entity.attr[k] = v }
      end
      if @params.has_key? :magic
        @params[:magic].each_pair {|k,v| @target.attr[k] = v }
      end
      if @params.has_key? :xfer
        if @params[:xfer][:amt].to_i > 0
          Bivouac.bank.give user: @target.id, type: @params[:xfer][:type], amt: @params[:xfer][:amt]
        else
          Bivouac.bank.take user: @target.id, type: @params[:xfer][:type], amt: @params[:xfer][:amt]
        end
      end
      if @params.has_key? :admin
        @params[:admin].each_pair {|k,v| @box.attr[k] = v }
      end
      if @params.has_key? :do
        if @params[:do] == 'save'
        @params[:app].each_pair {|k,v| @host.app[k] = v }
        @params[:env].each_pair {|k,v| @host.env[k] = v }
        end
      end
    end
    def goto
      @goto
    end
  end
end
