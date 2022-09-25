# frozen_string_literal: true

require 'json'
require 'dotenv'
require_relative './space_stone/env'
require_relative './space_stone/ia_download'
require_relative './space_stone/ocrcelot'
require_relative './space_stone/s3_service'
require_relative './space_stone/sqs_service'

# Invokers
def download(event:, context:) # rubocop:disable Lint/UnusedMethodArgument
  puts "event: #{event.inspect}" unless SpaceStone::Env.test?
  ia_ids = get_event_body(event: event)
  results = {}

  ia_ids.each do |ia_id|
    jp2s = process_ia_id(ia_id)
    results[ia_id] = jp2s.map { |v| v.sub('/tmp/', '') }
  end

  send_results(results)
end

def ocr(event:, context:) # rubocop:disable Lint/UnusedMethodArgument
  puts "event: #{event.inspect}" unless SpaceStone::Env.test?
  s3_locations = get_event_body(event: event)
  results = []
  s3_locations.each do |s3_location|
    path = SpaceStone::S3Service.download(s3_location)
    ocr_path = SpaceStone::Ocrcelot.new(path: path).ocr
    results << ocr_path
    SpaceStone::S3Service.upload(ocr_path)
  rescue Aws::S3::Errors::NotFound
    puts "file #{s3_location} not found. skipping"
  end
  send_results(results)
end

# Helpers
def process_ia_id(ia_id)
  FileUtils.mkdir_p("/tmp/#{ia_id}")
  # download zip file
  jp2s = SpaceStone::IaDownload.new(id: ia_id).download_jp2s

  jp2s.each do |path|
    SpaceStone::S3Service.upload(path)
    SpaceStone::SqsService.add(message: path.sub('/tmp/', ''), queue: 'ocr')
  end
end

def get_event_body(event:)
  if event['Records']
    event['Records'].map { |r| JSON.parse(r['body']) }.flatten
  elsif event['isBase64Encoded']
    JSON.parse(Base64.decode64(event['body']))
  else
    event['body']
  end
end

def send_results(results)
  {
    statusCode: 200,
    headers: [{ 'Content-Type' => 'application/json' }],
    body: results
  }.to_json
end
