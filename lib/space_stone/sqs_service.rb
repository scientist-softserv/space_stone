# frozen_string_literal: true

require 'aws-sdk-sqs'

module SpaceStone
  # Service object to add messages to either sqs queue
  module SqsService
    def client
      @client ||= Aws::SQS::Client.new(region: 'us-east-1')
    end

    def ocr_queue_url
      @ocr_queue_url ||= ENV['OCR_QUEUE_URL'] ||
                         client.get_queue_url({
                                                queue_name: 'space-stone-ocr-queue'
                                              })&.queue_url
    end

    def download_queue_url
      @download_queue_url ||= client.get_queue_url({
                                                     queue_name: 'space-stone-download-queue'
                                                   })&.queue_url
    end

    def add(message:, queue:)
      queue_url = send("#{queue}_queue_url")
      client.send_message({
                            queue_url: queue_url,
                            message_body: message.to_json
                          })
    end

    extend self
  end
end
