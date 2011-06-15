Amazon Marketplace Web Service Wrapper (MWS)
============================================

Experimental project. Trying to simplify using the Amazon MWS which is probably 
one of the worst implemented APIs. This won't look pretty.

Installing
----------

Add to Gemfile

    gem 'marketplacewebservice', :git => "git://github.com/spadin/marketplace-web-service.git"
    
then 

    $ bundle install
    
Usage
-----

I recommend keeping your Amazon credentials in an external file.

    credentials = YAML.load_file("#{Rails.root}/config/mws.yml")
    
Create MarketplaceWebService instance

    mws = MarketplaceWebService.new({
      merchant_id: current_seller.merchant_id,
      marketplace_id: current_seller.marketplace_id,
      credentials: {
        secret_key: credentials["secret_key"],
        access_key_id: credentials["access_key_id"]
      }
    })
    
Call methods of MWS with the instance variable you just made

    # Not very many MWS functions are supported yet.
    xml = mws.get_report_list
    
More details will come if this project gets more lovin'.