# frozen_string_literal: true

require 'spec_helper'

describe 'download' do # rubocop:disable RSpec/DescribeClass
  let(:jps) do
    [
      '/tmp/ShannaSchmidt32/jp2s/ShannaSchmidt32_0000.jp2',
      '/tmp/ShannaSchmidt32/jp2s/ShannaSchmidt32_0001.jp2',
      '/tmp/ShannaSchmidt32/jp2s/ShannaSchmidt32_0002.jp2',
      '/tmp/ShannaSchmidt32/jp2s/ShannaSchmidt32_0003.jp2',
      '/tmp/ShannaSchmidt32/jp2s/ShannaSchmidt32_0004.jp2'
    ]
  end
  let(:s3_jps) do
    { 'ShannaSchmidt32' => [
      'ShannaSchmidt32/jp2s/ShannaSchmidt32_0000.jp2',
      'ShannaSchmidt32/jp2s/ShannaSchmidt32_0001.jp2',
      'ShannaSchmidt32/jp2s/ShannaSchmidt32_0002.jp2',
      'ShannaSchmidt32/jp2s/ShannaSchmidt32_0003.jp2',
      'ShannaSchmidt32/jp2s/ShannaSchmidt32_0004.jp2'
    ] }
  end

  before do
    allow_any_instance_of(SpaceStone::IaDownload).to receive(:download_jp2s).and_return(jps)

    @upload_count = 0
    allow_any_instance_of(SpaceStone::S3Service).to receive(:upload) do
      @upload_count += 1
    end

    @add_count = 0
    allow_any_instance_of(SpaceStone::SqsService).to receive(:add) do
      @add_count += 1
    end
  end

  it 'returns a list of jp2s from http event' do
    expected_response = {
      statusCode: 200,
      headers: [{ 'Content-Type' => 'application/json' }],
      body: s3_jps
    }.to_json
    expect(download(event: event_data('http'), context: nil)).to eq(expected_response)
  end

  it 'returns a list of jp2s from sqs event' do
    expected_response = {
      statusCode: 200,
      headers: [{ 'Content-Type' => 'application/json' }],
      body: s3_jps
    }.to_json
    expect(download(event: event_data('sqs'), context: nil)).to eq(expected_response)
  end

  it 'saves jp2s to s3' do
    download(event: event_data('http'), context: nil)
    expect(@upload_count).to eq(5)
  end

  it 'queues up a job for ocr in sqs' do
    download(event: event_data('http'), context: nil)
    expect(@add_count).to eq(5)
  end
end
