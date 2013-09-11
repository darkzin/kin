# -*- coding: utf-8 -*-
require 'net/http'
require 'nokogiri'

def fetch(uri_str, limit = 10)
  # You should choose better exception.
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0
  url = URI.parse(uri_str)
  req = Net::HTTP::Get.new(url)
  response = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
  case response
  when Net::HTTPSuccess     then response
  when Net::HTTPRedirection then fetch(response['location'], limit - 1)
  else
    response.error!
  end
end

# if ARGV[0].nil?
#   puts "커맨드라인으로 키워드 입력바람!!"
#   exit
# end

keywords = File.new("keywordList.txt", "r:UTF-8")
links = File.new("links.txt", "w")

keywords.each do |keyword|
  # set parameter_hash.
  params = {
    key: "4f436982a6375823ea7affc3413c12ae",
    #query: ARGV[0],
    query: keyword.strip,
    display: (ARGV[1] || "10"),
    start: (ARGV[2] || "1"),
    target: "kin",
    sort: "sim"
  }

  # make query string.
  query_string = "/search?" + params.to_a.map { |array| array.join("=") }.join("&")
  puts query_string
  # make http request.
  http = Net::HTTP.new('openapi.naver.com')
  response = http.get(URI::encode(query_string))

  # parsing response to xml.
  kin_links = Nokogiri::XML(response.body).xpath("//item//link")

  if kin_links.empty?
    links.puts "키워드로 검색된 결과가 없습니다."
    puts "키워드로 검색된 결과가 없습니다."
    next
  end

  # each link follow redirect link, and get content, varify page has answer button or not.
  link_alive = ""

  kin_links.each do |link|
    response = fetch(link.content)
    if Nokogiri::HTML(response.body).css(".end_q_bottom .btn a").any?
      puts "got it!! : " + response.uri.to_s
      link_alive = response.uri.to_s
      break
    end
  end

  if link_alive.empty?
    links << "\n"
  else
    puts "alive..." + link_alive
    links << link_alive + "\n"
  end

end

keywords.close
links.close
