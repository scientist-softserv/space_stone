require 'test_helper'

module SpaceStone
  class EnvTest < TestCase

    it '.stage' do
      expect(Env.stage).must_equal('test')
    end

  end
end
