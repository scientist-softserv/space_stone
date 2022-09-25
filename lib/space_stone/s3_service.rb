# frozen_string_literal: true

require 'aws-sdk-s3'

module SpaceStone
  # Service object for upload and download to S3
  module S3Service
    def resource
      @resource ||= Aws::S3::Resource.new # (region: 'us-west-2')
    end

    def bucket
      @bucket ||= resource.bucket(ENV.fetch('AWS_S3_BUCKET'))
    end

    def upload(path)
      obj = bucket.object(path.sub('/tmp/', ''))
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
