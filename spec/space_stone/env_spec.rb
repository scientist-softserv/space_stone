# frozen_string_literal: true

require 'spec_helper'

describe 'Env' do
  it '.stage' do
    expect(SpaceStone::Env.stage).to eq('test')
  end
end
