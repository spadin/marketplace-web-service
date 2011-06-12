module MarketplaceWebService
  require 'net/https'
  require 'time'
  require 'cgi'
  require 'openssl'
  require 'base64'
  require 'nokogiri'
  
  @@aws_host = "mws.amazonservices.com"

  def initialize(merchant_id, marketplace_id)
    @merchant_id = merchant_id
    @marketplace_id = marketplace_id
    @credentials = load_credentials
  end

  def load_credentials(file)
    # #{Rails.root}/config/mws.yml
    YAML.load_file("#{file}")
  end
  
  def get_report_list
    query = build_query("GetReportList")

    # Make request
    xml = post query
    
    # Get test document.
    # xml = File.open("#{Rails.root}/test/fixtures/get_report_list.xml")
    
    # Return nokogiri object
    doc = Nokogiri::XML(xml)
  end
  
  def get_shipments_data
    doc = get_report_list
    report_id = doc.css("ReportType:contains('_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_')").first.parent().css("ReportId").text

    query = build_query("GetReport", {
      ReportId: report_id
    })

    # Make request - this request returns a CSV document
    csv = post query
    
    # Get test document.
    # csv = File.open("#{Rails.root}/test/fixtures/orders.csv")
  end
  
  def add_common!(params)
    params["SignatureVersion"] = "2"
    params["Timestamp"] = Time.now.gmtime.iso8601
    params["Version"] = "2009-01-01"
    params["SignatureMethod"] = "HmacSHA256"
    params["Acknowledged"] = "false"
  end
  
  def add_credentials!(params)
    params["MarketplaceIdList.Id.1"] = @marketplace_id
    params["Merchant"] = @merchant_id
    params["AWSAccessKeyId"] = @credentials["access_key_id"]
  end
  
  def make_signature(params)
    query =  "POST\n#{@@aws_host}\n/\n"
    query += params.collect {|key, value| key+"="+CGI.escape(value)}.join("&")
    
    # create digest of concatenated params
    digest = OpenSSL::Digest::Digest.new('sha256')
    hmac = OpenSSL::HMAC.digest(digest, @credentials["secret_key"], query)
    Base64.encode64(hmac).chomp
  end
  
  def build_query(action, extra_params = nil)
    params = Hash.new
    add_credentials! params
    add_common! params
    
    params["Action"] = action
    
    # Add extra parameters
    if !extra_params.nil?
      extra_params.each do |key,value|
        params[key.to_s] = value
      end
    end
    
    # case-insensitive sort by Hash key
    params = params.sort_by { |key,value| key }
    
    # Generate signature
    signature = make_signature params
    
    # params are URL-encoded, also add '=' and '&'
    query = params.collect {|key, value| key+"="+CGI.escape(value)}.join("&")
    
    # signature is URL-encoded, goes on end of URL (not sorted with other params)
    query += "&Signature=#{CGI.escape(signature)}"
  end
  
  def post(query)
    http = Net::HTTP.new(@@aws_host, 443)
    http.use_ssl = true
    req = Net::HTTP::Post.new('/?' + query)
    res = http.start { |http|
      http.request(req)
    }
    
    # return XML response
    res.body
  end
end
