require 'net/http'

module UserHelper

  #
  #
  #
  def self.fetch_gravatar(email, request)
    host = 'www.gravatar.com'
    port = 80
    email_md5 = Digest::MD5.hexdigest(email)
    path = "/avatar/#{email_md5}"
    request_headers = { 'Accept-Language' => request.env['HTTP_ACCEPT_LANGUAGE'],
                        'User-Agent' => request.env['HTTP_USER_AGENT'] }
    extra_response_headers = ['Content-Disposition']
    response = UserHelper.get_resource host, port, path, request_headers, extra_response_headers
    response.match(/filename="#{email_md5}\./).present? ? response.body : nil
  end

  #
  #
  #
  def self.fetch_random_avatar(request)
    avatar_image_data = [nil,nil]
bu = <<bu
p00=
p01=55
p02=41
p03=
p04=
p05=46
p06=31
p07=78
p08=13
p09=
p10=
p11=91
p12=
p13=
p14=
p15=&
bu
query = <<query
mode=img&\
download=&\
avatartext=&\
fontsize=12&\
fontcolor=%23000000&\
ytext=0&\
xtext=0&\
imgformat=png
query
    #valid_p_params = [1,2,5,6,7,8,11]
    valid_p_params = [1,2,3,4,5,6,7,8,9,10,11,12,13,14]
    p_params = ""
    #(0..15).each {|i| p_params = "#{p_params}&p#{i.to_s.ljust(2,"0")}=#{rand(100)}"}
    (0..15).each {|i| p_params = "#{p_params}&p#{i.to_s.ljust(2,"0")}=#{valid_p_params.include?(i) ? rand(100) : 0}"}
    color_params = ""
    color_params = "#{color_params}&haircolor=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&skincolor=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&eyecolor=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&lipcolor=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&warecolor1=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&warecolor2=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    color_params = "#{color_params}&warecolor3=%23#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}#{rand(255).to_s(16).upcase.ljust(2,"0")}"
    ordinate_params = ""
    (0..15).each {|i| ordinate_params = "#{ordinate_params}&y#{i.to_s.ljust(2,"0")}=0&x#{i.to_s.ljust(2,"0")}=0"}
    
    query_string = "#{query.lstrip.rstrip}#{p_params}#{color_params}#{ordinate_params}"
    puts "#{query_string}"
    
    target_host = "www3023ud.sakura.ne.jp"
    target_port = 80
    target_path = "/illustmaker/m.cgi?#{query_string}"
    target_req = Net::HTTP::Get.new(target_path)
    target_req.add_field("Host", target_host)
    target_req.add_field("Accept-Language", request.env['HTTP_ACCEPT_LANGUAGE'])
    target_req.add_field("User-Agent", request.env['HTTP_USER_AGENT'])
    #puts "target_req:\n#{target_req}"
    target_conn = Net::HTTP.new(target_host, target_port)
    target_conn.start do |http|
      http.request(target_req) do |target_res|
        avatar_image_data[0] = target_res.header["Content-Type"]
        avatar_image_data[1] = target_res.read_body
        ## hack since response is not decoded with png
        #cur_path = Rails.root.join('public', 'fotos', 'random_avatar')
        #File.open(cur_path, 'wb'){|file| file.write(target_res.read_body)}
        #avatar_image_data[1] = File.read(cur_path)
      end
    end
    avatar_image_data
  end

  #
  #
  #
  def self.get_resource host, port, path, request_headers = {}, extra_response_headers = []
    response_data = Struct.new(:content_type, :body)
    request = Net::HTTP::Get.new(target_path)
    request.add_field("Host", target_host)
    request_headers.each { |h, v| request.add_field(h.to_s, v) }
    target_conn = Net::HTTP.new(target_host, port)
    target_conn.start do |http|
      http.request(request) do |response|
        response_data.content_type = response.header["Content-Type"]
        extra_response_headers.each { |h| response_data[h] = response.header[h.to_s] }
        response_data.body = response.read_body
        ## hack since response is not decoded with png
        #cur_path = Rails.root.join('public', 'fotos', 'random_avatar')
        #File.open(cur_path, 'wb'){|file| file.write(response.read_body)}
        #response_data[1] = File.read(cur_path)
      end
    end
    response_data
  end

end
