# frozen_string_literal: true

require 'aws-sdk-s3'

module SpaceStone
  # Service object for upload and download to S3
  module S3Service
    def resource
      @resource ||= if ENV.fetch('AWS_S3_ACCESS_KEY_ID', nil)
        Aws::S3::Resource.new(region: ENV.fetch('AWS_S3_REGION'), credentials: Aws::Credentials.new(ENV.fetch('AWS_S3_ACCESS_KEY_ID'), ENV.fetch('AWS_S3_SECRET_ACCESS_KEY')))
      else
        Aws::S3::Resource.new
      end
    end

    def bucket
      @bucket ||= resource.bucket(ENV.fetch('AWS_S3_BUCKET'))
    end

    def upload(path, download_dir = '/tmp')
      obj = bucket.object(path.sub("#{download_dir}/", ''))
      puts "upload path #{path} - #{File.exist?(path)}"
      obj.upload_file(path)
    end

    def download(path)
      file_path = "/tmp/#{path}"
      FileUtils.mkdir_p(File.dirname(file_path))
      obj = bucket.object(path)
      obj.download_file(file_path)
      file_path
    end

    extend self
  end
end
