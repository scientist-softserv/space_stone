# frozen_string_literal: true

module SpaceStone
  # TODO: documentation
  # @see Hydra::Derivatives::Processors::Image
  class ThumbnailService
    attr_accessor :path

    def initialize(path:)
      @path = path.gsub(/[ \(\)\[\]\{\}~\$\&\%]/, '_')
    end

    # Default thumbnail output options in Hyrax v2.9.6:
    #
    # label: :thumbnail
    # format: 'jpg'
    # size: '200x150>'
    # url: derivative_url('thumbnail')
    # layer: 0
    #
    # @see Hyrax::FileSetDerivativesService
    def derive
      thumbnail_path = path.sub('/downloads/', '/thumbnails/').sub('.jp2', '.jpg')
      FileUtils.mkdir_p(File.dirname(thumbnail_path))

      cmd = "convert #{path} -thumbnail '200x150>' -flatten #{thumbnail_path}"
      puts cmd
      `#{cmd}`
    end
  end
end
