require 'net/http'

module UserHelper

  #
  #
  #
  def self.fetch_gravatar email, request = nil
    host = 'www.gravatar.com'
    port = 80
    email_md5 = Digest::MD5.hexdigest(email)
    path = "/avatar/#{email_md5}"
    extra_response_headers = ['Content-Disposition']
    if request.present?
      request_headers = { 'Accept-Language' => request.env['HTTP_ACCEPT_LANGUAGE'],
                          'User-Agent' => request.env['HTTP_USER_AGENT'] }
      response = self.get_resource host, port, path, request_headers, extra_response_headers
      response.extra_headers[extra_response_headers[0]].match(/filename="#{email_md5}\./).present? ? response : nil
    else
      response = self.head_resource host, port, path, {}, extra_response_headers
      response.extra_headers[extra_response_headers[0]].match(/filename="#{email_md5}\./).present? ? "http#{port==443 ? 's' : ''}://#{host}:#{port}#{path}" : nil
    end
  end

  #
  #
  #
  def self.fetch_random_avatar request = nil
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

    if request.present?
      request_headers = { 'Accept-Language' => request.env['HTTP_ACCEPT_LANGUAGE'],
                          'User-Agent' => request.env['HTTP_USER_AGENT'] }
      response_data = self.get_resource target_host, target_port, target_path, request_headers
      ## hack since response is not decoded with png
      #cur_path = Rails.root.join('public', 'fotos', 'random_avatar')
      #File.open(cur_path, 'wb'){|file| file.write(response_data.content)}
      #response_data.content = File.read(cur_path)
      response_data
    else
      "http#{target_port==443 ? 's' : ''}://#{target_host}:#{target_port}#{target_path}"
    end
  end

  #
  # 
  #
  def self.get url, request_headers = {}, extra_response_headers = [], redirects = []
    m = url.match(/^http(s?):\/\/([^:\/]+):?([^\/]*)(\/.*)/)
    ssl = m[1] == 's'
    get_resource m[2], m[3].present? ? m[3].to_i : (ssl ? 443 : 80), m[4], request_headers
  end

  #
  #
  #
  def self.head_resource host, port, path, request_headers = {}, extra_response_headers = []
    self.load_resource host, port, Net::HTTP::Head.new(path), request_headers, extra_response_headers
  end

  #
  #
  #
  def self.get_resource host, port, path, request_headers = {}, extra_response_headers = []
    self.load_resource host, port, Net::HTTP::Get.new(path), request_headers, extra_response_headers
  end

  #
  #
  #
  def self.load_resource host, port, request, request_headers = {}, extra_response_headers = [], redirects = []
    response_data = Struct.new(:response_code, :content_type, :extra_headers, :content, :redirects).new -1, nil, {}, nil, redirects
    request.add_field("Host", host)
    request_headers.each { |h, v| request.add_field(h.to_s, v) }
    target_conn = Net::HTTP.new(host, port)
    if port == 443
      target_conn.use_ssl = true
      target_conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    target_conn.start do |http|
      http.request(request) do |response|
        response_data.response_code = response.code
        if response.code  == '302'
          response_data.redirects.push response.header["Location"]
        else
          response_data.content_type = response.header["Content-Type"]
          extra_response_headers.each { |h| response_data.extra_headers[h] = response.header[h.to_s] }
          response_data.content = response.read_body
        end
      end
    end
    if response_data.response_code  == '302'
      return nil if redirects.size >= 3
      self.get(response_data.redirects.last, request_headers, extra_response_headers, redirects)
    else
      response_data
    end
  end

end
