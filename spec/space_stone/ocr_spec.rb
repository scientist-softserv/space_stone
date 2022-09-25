# frozen_string_literal: true

require 'spec_helper'

describe 'ocr' do # rubocop:disable RSpec/DescribeClass
  it 'runs tesseract on the file'
  it 'downloads a file from s3'
  it 'errors if the s3 file does not exist'
  it 'uploads the ocr files to s3'
  it 'returns the list of ocr files'
end
