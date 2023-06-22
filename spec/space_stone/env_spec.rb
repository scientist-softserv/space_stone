# frozen_string_literal: true

require 'spec_helper'

describe SpaceStone::Env do
  describe '.invoker_for' do
    subject { described_class.invoker_for(command, scope: SpaceStone::Invoker) }

    context 'when command is :ocr and no environmental defaults' do
      let(:command) { :ocr }

      it { is_expected.to eq(SpaceStone::Invoker::Ocr) }
    end

    context 'when command is :ocr with environmental defaults' do
      let(:command) { :ocr }
      around do |spec|
        SpaceStone::Invoker.const_set(:MyOcr, :INVOKER)
        spec.run
        SpaceStone::Invoker.send(:remove_const, :MyOcr)
      end

      it 'is expected to be the configured invoker' do
        allow(ENV).to receive(:[]).with("INVOKER__OCR").and_return("MyOcr")
        expect(subject).to eq(:INVOKER)
      end
    end
  end

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
