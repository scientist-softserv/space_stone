# frozen_string_literal: true

require 'spec_helper'

describe SpaceStone::ThumbnailService do
  it 'requires a :path argument' do
    expect { described_class.new }.to raise_error(ArgumentError, 'missing keyword: :path')
  end
end
