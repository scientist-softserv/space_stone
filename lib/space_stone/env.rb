# frozen_string_literal: true

module SpaceStone
  # Load env files for various lambda envs
  module Env
    def stage
      ENV['STAGE_ENV'] || 'development'
    end

    def test?
      stage == 'test'
    end

    def development?
      stage == 'development'
    end

    def region
      ENV['AWS_REGION'] || 'us-east-2'
    end

    extend self

    Dotenv.load(".env.#{stage}", '.env')
  end
end
