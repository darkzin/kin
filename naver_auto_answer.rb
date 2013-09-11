require 'rubygems'
require 'mechanize'

a = Mechanize.new { |agent| agent.user_agent_alias = 'Linux Firefox' }

id = "darkzin"
pw = "qjxmfjsem1"

a.get('http://nid.naver.com/nidlogin.login') do |page|
  page.form_with(name: "frmNIDLogin") do |f|
    f.add_field! "id", id
    f.add_field! "pw", pw
    f.url = "http://kin.naver.com"
  end.submit

  pp page
end
