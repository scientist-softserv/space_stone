# frozen_string_literal: true

require 'json'
require 'open3'
require 'tmpdir'

module SpaceStone
  # Ocrelot performa tesseract OCR extraction from jps2
  # it converts them to monochrome, depth 1 tiffs first
  class Ocrcelot
    attr_accessor :path

    OCR_CMD = 'OMP_THREAD_LIMIT=1 TESSDATA_PREFIX=/opt/share/tessdata LD_LIBRARY_PATH=/opt/lib /opt/bin/tesseract'

    def initialize(path:)
      @path = path.gsub(/[ \(\)\[\]\{\}~\$\&\%]/, '_')
    end

    def ocr
      mono_path = prep_file
      hocr_path = path.sub('/downloads/', '/ocr/')
      FileUtils.mkdir_p(File.dirname(hocr_path))
      cmd = "#{OCR_CMD} '#{mono_path}' #{hocr_path} hocr"
      run(cmd)
      file_path = "#{hocr_path}.hocr"
      raise 'generating OCR file failed' unless File.exist?(file_path)
      puts 'remove tmp files:'
      puts `rm -v #{mono_path}`
      file_path
    end

    def prep_file
      # /tmp/ShannaSchmidt32/download/ShannaSchmidt32_0000.jp2
      out_path = path.sub('/downloads/', '/tiffs/').sub('jp2', 'tiff')
      FileUtils.mkdir_p(File.dirname(out_path))
      opts = '-depth 1 -monochrome -compress Group4 -type bilevel'
      cmd = "convert '#{path}' #{opts} '#{out_path}'"
      run(cmd)
      raise 'generating TIFF file failed' unless File.exist?(out_path)
      out_path
    end

    def run(cmd)
      puts cmd
      `#{cmd}`
    end
  end
end
