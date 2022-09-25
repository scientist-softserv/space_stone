# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'tempfile'
require 'zip'

module SpaceStone
  # Download files from Internet Archive
  class IaDownload
    attr_accessor :id

    def self.json_data
      return @json_data if @json_data

      url = 'https://archive.org/services/xauthn/?op=login'
      json_string = HTTParty.post(url,
                                  body: { email: ENV.fetch('IA_USER', nil),
                                          password: ENV.fetch('IA_PASSWORD', nil) }).body
      @json_data = JSON.parse(json_string)
    end

    def self.login_cookies
      return @login_cookies if defined?(@login_cookies)

      raise 'failed to login to Internet Archive' unless json_data['success']

      cookie_hash = HTTParty::CookieHash.new
      cookie_hash.add_cookies("logged-in-user=#{json_data['values']['cookies']['logged-in-user']}")
      cookie_hash.add_cookies("logged-in-sig=#{json_data['values']['cookies']['logged-in-sig']}")
      @login_cookies = cookie_hash.to_cookie_string
    end

    def initialize(id:)
      @id = id
    end

    def login_cookies
      self.class.login_cookies
    end

    def remote_file_link
      return @remote_file_link if @remote_file_link

      url = "https://archive.org/download/#{id}/"
      response = HTTParty.post(url, headers: { 'Cookie' => login_cookies })
      page = Nokogiri::HTML(response.body)
      nodeset = page.css('a[href]')
      hrefs = nodeset.map { |element| element['href'] }
      jp2_zip_link = hrefs.grep(/jp2.zip/)&.first
      return '' unless jp2_zip_link

      @remote_file_link = url + jp2_zip_link
    end

    def jp2_path
      "/tmp/#{id}/jp2s"
    end

    def zip
      return @zip if @zip

      filename = File.basename(remote_file_link).split('.').first
      @zip = Tempfile.new(filename)
      @zip.binmode
      @zip.write(HTTParty.get(url, headers: { 'Cookie' => login_cookies }).body)
      @zip.close
    end

    def extract_file(zip_file)
      FileUtils.mkdir_p jp2_path
      zip_file.each do |zf|
        fpath = File.join(jp2_path, File.basename(zf.name))
        zip_file.extract(zf, fpath) unless File.exist?(fpath)
      end
    end

    def download_jp2s
      return [] unless remote_file_link.end_with?('.zip')

      Zip::File.open(zip.path) do |zip_file|
        extract_file(zip_file)
      end

      zip.delete
      Dir.glob("#{jp2_path}/*.jp2").sort.map { |f| File.expand_path(f) }
    end
  end
end
