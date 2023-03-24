# frozen_string_literal: true

require 'json'
require 'dotenv'
require_relative './space_stone/env'
require_relative './space_stone/ia_download'
require_relative './space_stone/ocrcelot'
require_relative './space_stone/s3_service'
require_relative './space_stone/sqs_service'

module SpaceStone
  module Invoker
    ##
    # @param command [Symbol] The name of the command you want to invoke
    # @param env [#invoker_for] The configuration for the command to use for this instance of SpaceStone.
    # @param scope [Module] The place where we'll look for a sub-module invoker.
    # @param kwargs [Hash<Symbol,Object>]
    #
    # @note Why this arrangement?  By the construction of a SpaceStone, you need methods in the
    #       global name space (e.g. in the Kernel).  And each project will have it's own set of
    #       invokers.  Some of those invokers would be re-used.  For example the OCR invoker.
    #       However, the invoker for downloading is perhaps unique.  What this allows for is a
    #       common repository to house scripts that might be generally userful and repurposable.
    def self.invoke(command, scope: self, env: SpaceStone::Env, **kwargs)
      env.invoker_for(command, scope: scope).call(**kwargs)
    end

    # @abstract
    class Base
      def self.call(event:, context:)
        new(event: event, context: context).call
      end

      def initialize(event:, context:)
        @event = event
        @context = context
        @body = body_from(event: @event)
      end
      attr_reader :event, :context, :body

      def call
        response_for(body: invoke)
      end

      def invoke
        raise NotImplementedError
      end

      private

      def response_for(body)
        {
          statusCode: 200,
          headers: [{ 'Content-Type' => 'application/json' }],
          body: body
        }.to_json
      end

      def body_from(event:)
        if event['Records']
          event['Records'].map { |r| JSON.parse(r['body']) }.flatten
        elsif event['isBase64Encoded']
          JSON.parse(Base64.decode64(event['body']))
        else
          event['body']
        end
      end
    end

    class DownloadInternetArchive < Base
      def invoke
        puts "event: #{event.inspect}" unless SpaceStone::Env.test?
        ia_ids = body
        results = {}

        ia_ids.each do |ia_id|
          jp2s = process_ia_id(ia_id.strip)
          results[ia_id] = jp2s.map { |v| v.sub('/tmp/', '') }
          puts %x{rm -rf /tmp/#{ia_id}}
        end

        results
      end

      private

      def process_ia_id(ia_id)
        FileUtils.mkdir_p("/tmp/#{ia_id}")
        # download zip file
        ia_download = SpaceStone::IaDownload.new(id: ia_id)
        downloads = ia_download.download_jp2s
        downloads += ia_download.dataset_files
        downloads.each do |path|
          SpaceStone::S3Service.upload(path)
          SpaceStone::SqsService.add(message: path.sub('/tmp/', ''), queue: 'ocr') if path.match(/jp2$/)
        end
      end
    end

    class Ocr < Base
      def invoke
        puts "event: #{event.inspect}" unless SpaceStone::Env.test?
        s3_locations = body
        results = []
        s3_locations.each do |s3_location|
          path = SpaceStone::S3Service.download(s3_location)
          ocr_path = SpaceStone::Ocrcelot.new(path: path).ocr
          results << ocr_path
          SpaceStone::S3Service.upload(ocr_path)
          puts "remove tmp files:"
          puts %x{rm -v #{path} #{ocr_path}}
        rescue Aws::S3::Errors::NotFound
          puts "file #{s3_location} not found. skipping"
        end

        results
      end
    end
  end
end

# Invokers
def download(event:, context:)
  SpaceStone::Invoker.invoke(:download, event: event, context: context)
end

def ocr(event:, context:)
  SpaceStone::Invoker.invoke(:ocr, event: event, context: context)
end
