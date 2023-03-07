# frozen_string_literal: true

module SpaceStone
  # TODO: documentation
  # @see Hydra::Derivatives::Processors::Image
  class ThumbnailDeriver
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
      thumbnail_path = path.sub('/downloads/', '/thumbnails/')
      FileUtils.mkdir_p(File.dirname(thumbnail_path))

      create_resized_image
    end

    # When resizing images, it is necessary to flatten any layers, otherwise the background
    # may be completely black. This happens especially with PDFs.
    def create_resized_image
      create_image do |xfrm|
        xfrm.combine_options do |i|
          i.flatten
          i.resize('200x150>')
        end
      end
    end

    def create_image
      xfrm = MiniMagick::Image.open(path).layers[0]
      yield(xfrm) if block_given?
      xfrm.format('jpg')
      write_image(xfrm)
    end

    def write_image(xfrm)
      output_io = StringIO.new
      xfrm.write(output_io)
      output_io.rewind
      # TODO: replace with our implementation
      # output_file_service.call(output_io, directives)
    end
  end
end
