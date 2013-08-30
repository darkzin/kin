# -*- coding: utf-8 -*-
require 'rubygems'
require 'open-uri'
require 'net/http'
require 'fileutils'
#require 'watir'
#require './aws'

def first_query(keyword)
  URI::encode("/search.naver?where=nexearch&query=" + keyword + "&sm=top_hty&fbm=1&ie=utf8")
end

def second_query(keyword)
  URI::encode("/search.naver?sm=tab_hty.btm&where=nexearch&ie=utf8&query=" + keyword + "&x=0&y=0")
end

def change_ip(instance_id, old_ip)
  uri = URI("https://ec2.ap-northeast-1.amazonaws.com/")

  #Allocate new ip.
  aws = AWS.new
  parameters = {}
  parameters['Action'] = 'AllocateAddress'
  #parameters['Domain'] = params[:vpc]

  aws_param = aws.build_query_params("2013-02-01", "2", parameters)
  res = aws.do_query("GET", uri.dup, aws_param)
  new_doc = Nokogiri::XML(res.body)
  new_doc.remove_namespaces!

  new_ip = new_doc.xpath("//publicIp").text

  #associate new ip.
  parameters = {}
  parameters['Action'] = 'AssociateAddress'
  parameters['InstanceId'] = instance_id
  parameters['PublicIp'] = new_ip

  aws_param = aws.build_query_params("2013-02-01", "2", parameters)
  aws.do_query("GET", uri.dup, aws_param)

  # send to message to server to recognize server of ip.
  Net::HTTP.start(new_ip, '3000') do |http|
    req = Net::HTTP::Options.new('*')
    http.request(req)
  end

  #release old ip.
  aws = AWS.new
  parameters = {}
  parameters['Action'] = 'ReleaseAddress'
  parameters['PublicIp'] = old_ip

  aws_param = aws.build_query_params("2013-02-01", "2", parameters)
  aws.do_query("GET", uri.dup, aws_param)



  return new_ip
end

# instance_id = ARGV[0]
# new_ip = ARGV[1]
path1 = URI::encode("/qna/detail.nhn?d1id=11&dirId=110803&docId=177980009&qb=7Iuc7JuQ7Iqk7L+o&enc=utf8&section=kin&rank=1&search_sort=0&spq=1")
#path2 = second_query(ARGV[3])

(1...200).each do |index|
  puts index.to_s
  http = Net::HTTP.new('kin.naver.com')
  # make a request to get the server's cookies
  response = http.get(path1)

  if (response.code == '200')
    puts "query success"
    sleep rand(10)

  else
    puts "query faild!!"
    break
  end
end
