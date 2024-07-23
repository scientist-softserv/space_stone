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

    def downloads_path
      return @downloads_path if @downloads_path

      @downloads_path = "/tmp/#{id}/downloads"
      FileUtils.mkdir_p @downloads_path
      @downloads_path
    end

    def zip
      return @zip if @zip

      filename = File.basename(remote_file_link).split('.').first
      @zip = Tempfile.create(filename, '/tmp')
      @zip.binmode
      # Stream the file directly to disk. If we stream into memory, we hit the lambda memory cap on large files
      begin
        File.open(@zip.path, 'wb') do |file|
          HTTParty.get(remote_file_link, headers: { 'Cookie' => login_cookies }, stream_body: true) do |fragment|
            raise "Non-success status code while downloading file: #{fragment.code}" unless fragment.code == 200

            file.write(fragment)
          end
        end
      ensure
        @zip.close
      end

      @zip
    end

    def extract_file(zip_file)
      zip_file.each do |zf|
        fpath = File.join(downloads_path, File.basename(zf.name))
        zip_file.extract(zf, fpath) unless File.exist?(fpath)
      end
    end

    def download_jp2s
      return [] unless remote_file_link.end_with?('.zip')

      Zip::File.open(zip.path) do |zip_file|
        extract_file(zip_file)
      end

      File.delete(zip.path)
      Dir.glob("#{downloads_path}/*.jp2").sort.map { |f| File.expand_path(f) }
    end

    def dataset_files
      return @dataset_files if @dataset_files

      @dataset_files = convert_dataset_links_to_files
      @dataset_files || []
    end

    def dataset_links
      url = "https://archive.org/download/#{id}/"
      response = HTTParty.post(url, headers: { 'Cookie' => login_cookies })
      page = Nokogiri::HTML(response.body)
      nodeset = page.css('a[href]')
      hrefs = nodeset.map { |element| element['href'] }
      @dataset_links = hrefs.grep(/.xls/)
      @dataset_links.map { |link| url + link }
    end

    def dataset_filename(link)
      file_name = link.split('/').last
      "#{downloads_path}/#{file_name}"
    end

    def convert_dataset_links_to_files
      dataset_links.each do |link|
        File.open(dataset_filename(link), 'w') do |file|
          file.binmode
          HTTParty.get(link, stream_body: true, headers: { 'Cookie' => login_cookies }) do |fragment|
            file.write(fragment)
          end
        end
      end
      Dir.glob("#{downloads_path}/*.xlsx").sort.map { |f| File.expand_path(f) }
    end
  end
end
