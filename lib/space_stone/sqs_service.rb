# frozen_string_literal: true

require 'aws-sdk-sqs'

module SpaceStone
  # Service object to add messages to either sqs queue
  module SqsService
    def client
      @client ||= if ENV.fetch('AWS_S3_ACCESS_KEY_ID', nil)
                    Aws::SQS::Client.new(region: 'us-east-2', credentials: Aws::Credentials.new(ENV.fetch('AWS_S3_ACCESS_KEY_ID'), ENV.fetch('AWS_S3_SECRET_ACCESS_KEY')))
                  else
                    Aws::SQS::Client.new(region: 'us-east-2')
                  end
    end

    def ocr_queue_url
      @ocr_queue_url ||= ENV['OCR_QUEUE_URL'] ||
                         client.get_queue_url({
                                                queue_name: 'space-stone-ocr-queue'
                                              })&.queue_url
    end

    def thumbnail_queue_url
      @thumbnail_queue_url ||= client.get_queue_url({
                                                      queue_name: 'space-stone-thumbnail-queue'
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

    def add_batch(messages:, queue:)
      queue_url = send("#{queue}_queue_url")
      client.send_message_batch({
        queue_url: queue_url,
        entries: messages
      })
    end

    extend self
  end
end
