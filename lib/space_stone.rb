# frozen_string_literal: true

require 'json'
require 'dotenv'
require_relative './space_stone/env'
require_relative './space_stone/ia_download'
require_relative './space_stone/ocrcelot'
require_relative './space_stone/thumbnail_service'
require_relative './space_stone/s3_service'
require_relative './space_stone/sqs_service'

# Invokers
# :download_dir must be a full path (i.e. starts with "/") and have no trailing slash
def download(event:, context:, download_dir: '/tmp') # rubocop:disable Lint/UnusedMethodArgument
  puts "event: #{event.inspect}" unless SpaceStone::Env.test?
  ia_ids = get_event_body(event: event)
  results = {}

  ia_ids.each do |ia_id|
    jp2s = process_ia_id(ia_id.strip, download_dir)
    results[ia_id] = jp2s.map { |v| v.sub("#{download_dir}/", '') }
    puts %x{rm -rf #{download_dir}/#{ia_id}}
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
    puts "remove tmp files:"
    puts %x{rm -v #{path} #{ocr_path}}
  rescue Aws::S3::Errors::NotFound
    puts "file #{s3_location} not found. skipping"
  end

  send_results(results)
end

def thumbnail(event:, context:)
  puts "event: #{event.inspect}" unless SpaceStone::Env.test?
  s3_locations = get_event_body(event: event)
  results = []
  s3_locations.each do |s3_location|
    path = SpaceStone::S3Service.download(s3_location)
    thumbnail_path = SpaceStone::ThumbnailService.new(path: path).derive
    results << thumbnail_path
    SpaceStone::S3Service.upload(thumbnail_path)
  rescue Aws::S3::Errors::NotFound
    puts "file #{s3_location} not found. skipping"
  end
  send_results(results)
end

# Helpers
def process_ia_id(ia_id, download_dir)
  FileUtils.mkdir_p("#{download_dir}/#{ia_id}")
  # download zip file
  ia_download = SpaceStone::IaDownload.new(id: ia_id, base_path: download_dir)
  downloads = ia_download.download_jp2s
  downloads += ia_download.dataset_files
  downloads.each do |path|
    SpaceStone::S3Service.upload(path, download_dir)
    SpaceStone::SqsService.add(message: path.sub("#{download_dir}/", ''), queue: 'ocr') if path.match(/jp2$/)
    SpaceStone::SqsService.add(message: path.sub("#{download_dir}/", ''), queue: 'thumbnail') if path.match(/jp2$/)
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
