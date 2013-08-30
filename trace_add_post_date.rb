# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'xmlrpc/client'
require 'net/http'
require 'fileutils'
require 'net/sftp'
require 'watir-webdriver'
require 'debugger'

posts = File.new('postlist.txt')
dates = File.new('datelist.txt', 'w')
browser = Watir::Browser.new

posts.each do |url|
  if url.strip.empty?
    dates << "\n"
  else
    begin
      browser.goto url
      date = browser.frame(:id, "mainFrame").p(:class, "_postAddDate").text
      post_date = Date.strptime(date, "%Y/%m/%d").strftime("%-m월 %-d일")
      puts post_date
      dates << post_date + "\n"
    rescue
      url = browser.frame(:id, "screenFrame").src
      retry
    end
  end
end

posts.close
dates.close
