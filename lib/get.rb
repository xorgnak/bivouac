module Bivouac
  class Get
    def initialize path, request, params
      @path, @request, @params = path, request, params
      log "#{params}", "GET.#{@path}"
    end
  end
end
