# frozen_string_literal: true

module SpaceStone
  # TODO
  class ThumbnailDeriver
    attr_accessor :path

    def initialize(path:)
      @path = path.gsub(/[ \(\)\[\]\{\}~\$\&\%]/, '_')
    end

    # TODO: implement
    def derive; end
  end
end
