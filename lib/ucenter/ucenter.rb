require 'rack'
require 'digest'
require 'base64'
require 'uri'
require 'net/http'
require 'nokogiri'

module UCenter

  class UCenter

    def initialize(agent: nil)
      @uc_client_release = '20110501'
      @uc_appid   = ::UCenter.configuration.appid
      @uc_key     = ::UCenter.configuration.key
      @uc_api     = ::UCenter.configuration.api
      @uc_charset = ::UCenter.configuration.charset.downcase
      @uc_charset = ['utf-8', 'gbk'].find_index(@uc_charset) ? @uc_charset : 'gbk'
      @agent = agent || ::UCenter.configuration.default_agent
    end

    def user_login (username, password)
      response = uc_api_post('user', 'login', {username: encode(username), password: password, isuid: 0, checkques: 0, questionid: '', answer: ''})
      uc_parse_user_info(response, [:id, :nick, :password, :email])
    end

    def user_synlogin(uid)
      uc_api_post('user', 'synlogin', {uid: uid})
    end

    def user_register(username, password, email, mobile = nil)
      new_uid = uc_api_post('user', 'register',  {username: encode(username), password: password, email: email, questionid: '', answer: mobile, regip: ''}).to_i
      new_uid > 0 ? new_uid : 0
    end

    def user_checkname(username)
      uc_api_post('user', 'check_username', {username: username}) == '1'
    end

    def user_checkmail(email)
      uc_api_post('user', 'check_email', {email: email}) == '1'
    end

    def user_synlogout(uid)
      uc_api_post('user','synlogout',{uid: uid})
    end

    def user_resetpwd(username,pass)
      resp = uc_api_post('user','edit',{username: encode(username),newpw: pass,ignoreoldpw: 1})
      resp == '1' || resp == '0'
    end

    def get_user (username, isuid = 0)
      response = uc_api_post('user', 'get_user', {username: encode(username), isuid: isuid})
      uc_parse_user_info(response, [:id, :nick,:email])
    end

    def user_edit(username, oldpw, newpw, email, ignoreoldpw = 1)
      response = uc_api_post('user', 'edit', {username: encode(username), oldpw: oldpw, newpw: newpw, email: email, ignoreoldpw: ignoreoldpw, questionid: '', answer: ''})
      response
    end

    def user_delete(uid)
      uc_api_post('user', 'delete', {uid: uid}) == '1'
    end

    private

    def encode str
      if @uc_charset.downcase == 'gbk'
        str.encode('gbk', 'utf-8')
      else
        str
      end
    end

    def authcode(string, operation, expiry = 0)
      ckey_length = 4
      key  = @uc_key
      key  = Digest::MD5.hexdigest(key)
      keya = Digest::MD5.hexdigest(key[0,16])
      keyb = Digest::MD5.hexdigest(key[16,16])

      keyc = if ckey_length > 0
               if operation == 'DECODE'
                 string[0, ckey_length]
               else
                 now = Time.now
                 microtime = "#{(now.to_f - now.to_i).to_s[0,10]} #{now.to_i}"
                 Digest::MD5.hexdigest(microtime)[-ckey_length,ckey_length]
               end
             else ''
             end

      cryptkey = keya + Digest::MD5.hexdigest(keya + keyc)
      key_length = cryptkey.size

      string = operation == 'DECODE' ?
        Base64.decode64(string[ckey_length, string.length - ckey_length]) :
        format('%010d',(expiry != 0 ? expiry + Time.now.to_i : 0)).to_s  + Digest::MD5.hexdigest(string+keyb)[0,16] + string

      string_length = string.size

      result = ''
      box = {}
      (0..255).each {|i| box[i] = i }
      rndkey = {}

      (0..255).each  { |i| rndkey[i] = cryptkey[i % key_length].ord }

      j = 0
      (0..255).each do |i|
        j = (j + box[i] + rndkey[i]) % 256
        tmp = box[i]
        box[i] = box[j]
        box[j] = tmp
      end

      a = j =0
      (0..string_length-1).each do |i|
        a = (a + 1) % 256
        j = (j + box[a]) % 256
        tmp = box[a]
        box[a] = box[j]
        box[j] = tmp
        result << ((string[i]).ord ^ box[(box[a] + box[j]) % 256]).chr
      end

      if operation == 'DECODE'
        if result[0,10].to_i == 0 || result[0,10].to_i - Time.now.to_i > 0
          return result[26,result.size - 26]
        else
          return ' '
        end
      else
        return keyc + Base64.encode64(result).gsub('=', '').gsub(/\n/,'')
      end
    end

    def uc_api_post(mod, action, args)
      s = sep = ''
      args.each do |k, v|
        s << "#{sep}#{k}=#{Rack::Utils.escape v}"
        sep = '&'
      end
      postdata = uc_api_requestdata(mod, action, s)
      uc_fopen(@uc_api + '/index.php', postdata)
    end

    def uc_api_requestdata(mod, action, arg, extra = '')
      input = uc_api_input(arg)
      "m=#{mod}&a=#{action}&inajax=2&release=#{@uc_client_release}&input=#{input}&appid=#{@uc_appid}#{extra}"
    end

    def uc_api_url(mod, action, arg, extra)
      @uc_api + '/index.php?' + uc_api_requestdata(mod, action, arg, extra)
    end

    def uc_api_input(data)
      agent = defined?(request) ? request.env['HTTP_USER_AGENT'] : @agent
      time  = Time.now.to_i
      url   = "#{data}&agent=#{Digest::MD5.hexdigest agent}&time=#{time}"
      Rack::Utils.escape(authcode(url, 'ENCODE'))
    end

    def uc_fopen(url, post)
      uri = URI.parse("#{url}?#{post}")
      http = Net::HTTP.new(uri.host, uri.port)
      agent = defined?(request) ? request.env['HTTP_USER_AGENT'] : @agent
      request = Net::HTTP::Get.new(uri.request_uri)
      request.initialize_http_header({'User-Agent' => agent})
      http.request(request).body
    end

    def uc_parse_user_info(response, fields)
      xml =  Nokogiri::XML(response)
      result = {}
      if xml
        fields.zip([1,3,5,7]).each do |k,i|
          result[k]  =  xml.root.children[i].text.encode('iso-8859-1').force_encoding(@uc_charset).encode('utf-8')
        end
        result[:id] = result[:id].to_i
      end
      return result
    end

  end


end
