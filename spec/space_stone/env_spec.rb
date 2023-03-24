# frozen_string_literal: true

require 'spec_helper'

describe SpaceStone::Env do
  describe '.stage' do
    subject { described_class.stage }

    context 'default' do
      it { is_expected.to eq('test') }
    end
  end

  context '.project' do
    subject { described_class.project }

    context 'default' do
      it { is_expected.to eq('nnp') }
    end
  end
end
