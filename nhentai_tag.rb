require 'nokogiri'
require 'rest-client'
require 'open-uri'
require 'fileutils'
require 'progress_bar'
include ProgressBar::WithProgress

class Nhentai
  
  attr_reader :tag, :sort, :page
  
  def initialize(tag, sort, page)
    @tag = tag.chomp.downcase.tr(' ','-')
    @sort = sort
    @page = page.chomp
  end
  
  def run
    listing
    scrapping
  end
  
  private
  
  def parsing(url)
    html = RestClient.get(url)
    Nokogiri::HTML(html)
  rescue StandardError => e
    puts "Maybe this tag does not exist..? #{url}"
    puts "Exeception Class:#{e.class.name}"
    puts "Exception Message:#{e.message}"
  end
  
  def url_base
    @url_base ||= "https://nhentai.net/tag/#{tag}/#{sort}?page=#{page}"
  end
  
  def listing
    @doujinshis_urls = Array.new
    parsed_html = parsing(url_base)
    doujinshis = parsed_html.xpath('/html/body/div[2]/div[2]/div/a')
    doujinshis.each{|doujin| @doujinshis_urls << doujin.attr('href')}
  end
  
  def scrapping 
    FileUtils.mkdir "#{tag}_page_#{page}"
    Dir.chdir("#{Dir.pwd.chomp}/#{tag}_page_#{page}") do
      @doujinshis_urls.each do |doujin|
          doujinshi_url = "https://nhentai.net#{doujin}"
          parsed_html = parsing(doujinshi_url)
          @title = info(parsed_html)
          folder = FileUtils.mkdir "#{@title}"
          puts "Downloading #{@title}"
          (1..@total).each_with_progress do |i|
            page_url = "#{doujinshi_url+i.to_s}"
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
    end
  end
  
  def info(url)
    @total = url.css('div#thumbnail-container>div>a>img').count
    url.xpath('/html/body/div[2]/div/div[2]/div/h1').text
  end
  

end

puts "/---NHENTAI TAG DOWNLOADER---/"
puts "This script will download all avaliable manga from given page."
puts "-----------------------------------------------------------------"
puts "Type your TAG: "
tag = gets

puts "Would you like to sort by popular [y/n] ?"
sort = gets
if sort == "y"
  sort = "popular"
else
  sort = nil
end

puts "Which page want to download ?"
page = gets
puts "Running...."
pevert = Nhentai.new(tag, sort, page)
pevert.run