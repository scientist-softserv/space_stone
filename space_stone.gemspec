# frozen_string_literal: true

require_relative "lib/space_stone/version"

Gem::Specification.new do |spec|
  spec.name = "space_stone"
  spec.version = SpaceStone::VERSION
  spec.authors = ["Rob Kauffman", "Jeremy Friesen"]
  spec.email = ["rob@notch8.com", "jeremy.n.friesen@gmail.com"]

  spec.summary = "A tool for leveraging AWS for file processing."
  spec.description = "A tool for leveraging AWS for file processing."
  spec.homepage =  "https://github.com/scientist-softserv/space_stone"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/scientist-softserv/space_stone"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk-s3'
  spec.add_dependency 'aws-sdk-sqs'
  spec.add_dependency 'dotenv'
  spec.add_dependency 'httparty'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'rubyzip'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'


  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
