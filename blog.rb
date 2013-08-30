require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'xmlrpc/client'
require 'net/http'
require 'fileutils'
require 'net/sftp'

gameList = File.new('gamelist.txt')

gameList.each do |game|
	gameInfo = game.split("\t")
	gameName = gameInfo[0]
	postId = gameInfo[1].delete("\n")

	puts "game name : #{gameName}, post id : #{postId}"
	# gameName = "roomBreak"
	# postId = "150155601736"
	server = XMLRPC::Client.new2('https://api.blog.naver.com/xmlrpc')
	# posts = server.call('metaWeblog.getRecentPosts', 'tongplay1910', 'tongplay1910', '5bb68692580a6d605c4dc3e5bcb3f5df', 5)
	posts = server.call('metaWeblog.getPost', postId, 'tongplay1910', '5bb68692580a6d605c4dc3e5bcb3f5df')
	post = posts['description']

	doc = Nokogiri::HTML(post)
	doc.css("p[style], span[style], a[style]").each do |tag|
		value = tag['style']

		value.gsub!(/FONT-SIZE: [0-9]+pt/i) do |match|
			match = "FONT-SIZE: " + (match.delete("^0-9").to_i + 5).to_s + "pt"
		end

		tag['style'] = value
	end

	unless File.directory? "#{gameName}" then
		FileUtils.mkdir("#{gameName}")
	end

	doc.css("img").each_with_index do |img, index|
		src = img['src']
		# puts src
		if (qmarkIndex = src.index('?')) then
			srcRemovingParameter = src[0...qmarkIndex]
			# puts "change : " + src
		end
		extname = File.extname(srcRemovingParameter || src)

		# unless(extname == ".png" || extname == ".jpg" || extname == ".jpeg") then
		# 	break
		# end



		fileName = "#{gameName}_#{index}#{extname}"

		open(src) do |f|
		   File.open("#{gameName}/" + fileName,"wb") do |file|
	    	file.puts f.read
		   end
		end

		img['src'] = "http://app.gametong.tv/upload/editor/review/#{gameName}/#{fileName}"
	end

	Net::SFTP.start("125.141.225.55", "root", :password => "xhd%^&") do |sftp|
		begin
			sftp.stat!("/home/NAS/WAS/gameupload/upload/editor/review/#{gameName}").directory?
		rescue
			sftp.mkdir! "/home/NAS/WAS/gameupload/upload/editor/review/#{gameName}", :permissions => 0555
		end

		sftp.upload!("#{gameName}",  "/home/NAS/WAS/gameupload/upload/editor/review/#{gameName}")
	end
	# doc.css("img").remove
	# doc.css("br").remove

	# puts doc



	# puts fonts[0]

	# doc = Nokogiri::HTML(server.call('metaWeblog.getPost', '150155546151', 'tongplay1910', '5bb68692580a6d605c4dc3e5bcb3f5df')['description'])
	# puts doc
	# url = "http://blog.naver.com/PostView.nhn?blogId=tongplay1910&logNo=150155546151"
	# doc = Nokogiri::HTML(open(url))

	File.open("#{gameName}/#{gameName}.html", 'w:UTF-8') do |post|
		post.puts doc.to_html
	end
end