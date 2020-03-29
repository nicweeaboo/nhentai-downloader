require 'nokogiri'
require 'rest-client'
require 'open-uri'
require 'fileutils'
require 'progress_bar'
include ProgressBar::WithProgress

class Nhentai

  attr_reader :url_base
  
  def initialize(url_base)
    @url_base = url_base.chomp
  end
  
  def run
    scrapping
  end

  def parsing(url)
    html = RestClient.get(url)
    Nokogiri::HTML(html)
  rescue StandardError => e
    puts "Maybe this link does not exist..? #{url}"
    puts "Exeception Class:#{e.class.name}"
    puts "Exception Message:#{e.message}"
  end
  
  def scrapping
    parsed_html = parsing(url_base)
    @title = info(parsed_html)
    folder = FileUtils.mkdir "#{@title}"
    puts "Downloading #{@title}"
    (1..@total).each_with_progress do |i|
      page_url = "#{url_base+i.to_s}"
      page_parsed = parsing(page_url)
      image = page_parsed.xpath('/html/body/div[2]/div/section[2]/a/img').attr('src').text
      Dir.chdir("#{Dir.pwd.chomp}/#{folder.join(" ")}") do
        puts "Downloading page #{i}/#{@total}"
        File.open("page#{i}", "wb") do |f|
          f.write open(image).read
        end
      end
    end
  end
  
  def info(url)
    @total = url.css('div#thumbnail-container>div>a>img').count
    url.xpath('/html/body/div[2]/div/div[2]/div/h1').text
  end
  
end

puts "/---NHENTAI TAG DOWNLOADER---/"
puts "-----------------------------------------------------------------"
puts "Paste your url: "
url_base = gets
pevert = Nhentai.new(url_base)
pevert.run