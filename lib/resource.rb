require 'lib/struct'
module Poppet
  class Resource < Struct
    def self.schema
      Struct.schema_for( "resource", "0", "object", ["optional", "object"], "struct", true )
    end

    def [](name)
      @data["data"][name]
    end

    def keys
      @data["data"].keys
    end
  end
end

