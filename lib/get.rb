module Bivouac
  class Get
    def initialize request, params
      @request, @params = request, params
      log "#{params}", "Get.#{@path}"
    end
    def path
      @request.host
    end
  end
end
