# frozen_string_literal: true

module SpaceStone
  # Load env files for various lambda envs
  module Env
    # What is the project that this is associated with?
    def project
      # The original "space stone" project was "nnp".  For backwards compatability, I'm going using
      # that so as to create the least disruption.
      ENV['SPACE_STONE_PROJECT'] || 'nnp'
    end

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
