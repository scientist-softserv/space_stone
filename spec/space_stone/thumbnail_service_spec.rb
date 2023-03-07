# frozen_string_literal: true

require 'spec_helper'

describe SpaceStone::ThumbnailService do
  let(:path) { './spec/fixtures/downloads/image.jp2' }
  let(:thumbnail_location) { './spec/fixtures/thumbnails/image.jpg' }
  subject(:thumbnail_service) { described_class.new(path: path) }

  it 'requires a :path argument' do
    expect { described_class.new }.to raise_error(ArgumentError, 'missing keyword: :path')
  end

  after do
    File.delete(thumbnail_location) if File.exists?(thumbnail_location)
  end

  describe '#derive' do
    it 'derives a thumbnail from a path' do
      expect(File.exists?(thumbnail_location)).to eq(false)

      thumbnail_service.derive

      expect(File.exists?(thumbnail_location)).to eq(true)
    end
  end
end
