ENV['STAGE_ENV'] = 'test'
require 'bundler' ; Bundler.require :development, :test
require_relative '../lib/space_stone'
require 'minitest/autorun'

module SpaceStone
  class TestCase < MiniTest::Spec

    before do
      #
    end

    after do
      #
    end

    private

    def event_data(fname)
      file = File.join root, 'events', "#{fname}.json"
      JSON.load(File.read(file))
    end

    def root
      File.expand_path(__dir__)
    end

  end
end
