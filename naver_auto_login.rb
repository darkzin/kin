# -*- coding: utf-8 -*-
require 'net/http'
require 'nokogiri'
require 'open-uri'
require 'http-cookie'

def fetch(uri_str, jar, referer = "", limit = 15)
  # You should choose a better exception.
  raise ArgumentError, 'too many HTTP redirects' if limit == 0

  uri = URI(uri_str)
  http = Net::HTTP.new(uri.hostname, uri.port)
  uri_path = uri.path.empty? ? "/" : uri.path
  uri_path += not(!uri.query.nil? && uri.query.empty?) ? "?#{uri.query}" : ""

  puts "uri path: " + uri_path
  response = http.request_get(uri_path, "Referer" => referer, "Cookie" => HTTP::Cookie.cookie_value(jar.cookies(uri)))

  case response
  when Net::HTTPSuccess then
    if response.body.include? "window.location.replace"
      location = response.body[/\".*\"/].delete('"')
      jar.parse(response["Set-Cookie"], uri)
      fetch(location, jar, "", limit - 1)
    else
      response
    end
  when Net::HTTPRedirection then
    location = response['location']
    warn "redirected to #{location}"
    fetch(location, jar, "", limit - 1)
  else
    response.value
  end
end

id = "darkzin"
pw = "qjxmfjsem1"

uri = URI("http://nid.naver.com/nidlogin.login")
params = { enctp: "2", svctype: "0", id: id, pw: pw, url: "http://kin.naver.com/qna/detail.nhn?d1id=5&docId=180062945&dirId=502" }
uri.query = URI.encode_www_form(params)

req = Net::HTTP::Post.new(uri.path + "?" + uri.query, {
    "ContentType" => "application/x-www-form-urlencoded",
    "Referer" => "https://nid.naver.com/nidlogin.login"
  })

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

jar = HTTP::CookieJar.new

case res
when Net::HTTPSuccess
  # puts res['location']
  # puts "Cookie: "
  # puts cookie += res.response['set-cookie']
  jar.parse(res["Set-Cookie"], uri)
  resp = fetch(res.body[/\".*\"/].delete('"'), jar)
  doc = Nokogiri::HTML(resp.body)
  answer_url = doc.css(".end_q_bottom .btn a").first['onclick']

  # puts "response body: "
  # puts resp.body
  # puts "next: "
  # puts "Cookie: "
  # puts cookie += resp.response['set-cookie']
  # respo = fetch(res.body[/\".*\"/].delete('"'), cookie)
  # puts "response body: "
  # puts respo
  # puts "Cookie: "
  # puts cookie += respo.response['set-cookie'] unless respo.response['set-cookie'].nil?
  # puts cookie
when Net::HTTPRedirection
  puts fetch(res['location'], cookie).body
else
  puts res.value
end

answer_path = answer_url[/\'.*\',/].delete("'").delete(",").strip
puts res = fetch("http://kin.naver.com" + answer_path, jar)
referer =  Nokogiri::HTML(res.body).css("iframe#editor").first['src']

frame_uri = URI("http://kin.naver.com" + referer)

frame_res = fetch(frame_uri, jar, "http://kin.naver.com" + answer_path)

Nokogiri::HTML(frame_res.body).css("#answerForm input[type='hidden']").each do |input|
  puts input['name']
  puts input['value']
end

uri = URI("http://kin.naver.com/qna/process.nhn?m=answer")
params = {}
Nokogiri::HTML(frame_res.body).css("#answerForm input[type='hidden']").each do |input|
  params[input['name']] = input['value']
end

params['title'] = '시원스쿨 탭'
params['contents'] = "시원스쿨 탭을 사지 않으신다면 <br/> 일반적인 탭을 구입 후 <br/>"
params.merge ({
  rows_val: "4",
  cols_val: "4",
  border_val: "1",
  borderColorCode: "#B7BBB5",
  backColorCode: "#FFFFFF",
  keyword: "",
  keyword_re: "",
  replace: "",
  search_input: "",
  source: "",
  choose_namcard: "user",
  captchaValue: ""
})

puts params.inspect
req = Net::HTTP::Post.new(uri.path + "?" + uri.query, {
    "ContentType" => "application/x-www-form-urlencoded",
    "Referer" => frame_uri.to_s,
    "Cookie" => HTTP::Cookie.cookie_value(jar.cookies(uri))
  })

req.set_form_data(params)

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts res.body
# jar.each do |cookie|
#   puts " "
#   puts cookie.name
#   puts cookie.value
#   puts cookie.domain
# end

# uri = URI("http://kin.naver.com/qna/process.nhn?m=answer")
# params = {
#   dirId: "",
#   docId: "",
#   svc: "KIN",
#   openFlag: "N",
#   rssFlag: "N",
#   addedInfoStruct: "",
#   mapAttachStruct: "",
#   temporaryId: "",
#   expertiseAnswerableFlag: "false",
#   tempField: "",
#   inputDevice: "PC",
#   captchaType: "image",
#   captchaKey: "",
#   cafeId: "0",
#   menuId: "0",
#   eventNo: "-1",
#   mdu: "",
#   title: "",
#   contents: "",
#   rows_val: "4",
#   cols_val: "4",
#   border_val: "1",
#   borderColorCode: "#B7BBB5",
#   backColorCode: "#FFFFFF",
#   keyword: "",
#   keyword_re: "",
#   replace: "",
#   search_input: "",
#   source: "",
#   choose_namcard: "user",
#   captchaValue: ""
# }

# uri.query = URI.encode_www_form(params)

# req = Net::HTTP::Post.new(uri.path + "?" + uri.query, {
#     "ContentType" => "application/x-www-form-urlencoded",
#     "Referer" => "https://nid.naver.com/nidlogin.login"
#   })

# res = Net::HTTP.start(uri.hostname, uri.port) do |http|
#   http.request(req)
# end
