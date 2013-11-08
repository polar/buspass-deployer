#
# Do not put this file into source code control. It contains sensitive information that will be
# configured for any Heroku instance anyway.
#

puts "Setting Local Development Environment Vars"

ENV['DISABLE_FORWARD_PROXY']='1'
ENV["PORT"]='3000'
ENV["INSTALLATION"] = "Stage"

#
# The following file assigns ENV["INSTALLATION"] when operating locally in development, otherwise
# this file will not exist and not be read. "development_env" is in source code control,
# which maybe different depending on which source code control branch we residing. That enables
# us to switch environments base on the current source code control branch.
#
# This comes in handy when we need to precompile assets and sync them with the ASSET_HOST.
#
develop_env = File.expand_path("./installation_env.rb", File.dirname(__FILE__))
require develop_env if File.exists?(develop_env)

#ENV["MASTER_SLUG"]="syracuse-university"

#ENV["INSTALLATION"] = "Stage"
#ENV["BUSME_BASEHOST"] = "ec2-54-235-9-165.compute-1.amazonaws.com"
#ENV["BUSME_BASEHOST"] = "busme-stage.adiron.com"

#ENV["BUSME_BASEHOST"] = "localhost"
#ENV["BUSME_BASEHOST"] = "skylight.local"
#ENV["BUSME_PORT"] = "3002"

case ENV["INSTALLATION"]
  when "Stage"
    ENV["FRONTEND"]="localhost"
    ENV["BACKEND"]= "Z-localhost-localhost-0.0.0.0-127.0.0.1-3000-0.0.0.0-4000"
    ENV["SWIFT_ENDPOINT"]="busme-2-localhost"
    ENV['MONGOLAB_URI']="mongodb://busme-test:busme-test@ds037768.mongolab.com:37768/heroku_app10086460"
    ENV['S3_BUCKET_NAME'] ="busme-stage-files"
    ENV['ASSET_DIRECTORY']="busme-stage-assets"

  when "Production"
    # This is our live environment on Heroku for "busme.us"
    ENV["FRONTEND"] = "busme.us"
    ENV['MONGOLAB_URI']="mongodb://busme-db:busme-db@ds043047.mongolab.com:43047/busme-initial"
    ENV["SWIFT_ENDPOINT"]="busme-2-localhost"
    ENV['ASSET_DIRECTORY']="busme-assets"
    ENV['S3_BUCKET_NAME'] ="busme-test"

  else
    puts "Unregistered Installation"
    exit 1
end

ENV['FOG_PROVIDER'] ="AWS"
ENV['ASSET_HOST']="//#{ENV['ASSET_DIRECTORY']}.s3.amazonaws.com"


ENV['SWIFTIPLY_KEY']="32423462347987ab3247893cd89324732ef89234237ab32847289347c987832498d8e078674369a792834832cb897342387def98789324723489fea83247v"
ENV['HEROKU_API_KEY']="4656ffc212fa434174b98c585cee8bd44f31f591"
ENV['AWS_ACCESS_KEY_ID']="AKIAJBFXGMNAJJD6DVRA"
ENV['AWS_SECRET_ACCESS_KEY']="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"

ENV['INTERCOM_APPID']='i6xnzxqx'

#
# These were needed for OmniAuth. We may not need them any more.
#
ENV["TWITTER_ID"]='uLdnGzffvlbCX0sIKpBJtg'
ENV["TWITTER_SECRET"]='cekT1OocNuYOoV2apgNerlDBxrzmQllHBnhrrT5I'
ENV["FACEBOOK_ID"]='458379574194172'
ENV["FACEBOOK_SECRET"]='69bb8e7b2655042f4cfd908e1576c08f'
ENV["GOOGLE_ID"]='busme.us'
ENV["GOOGLE_SECRET"]='LelxfeNM_Byuvhv6tU6oGvAh'
ENV["LINKEDIN_ID"]='1wmmzdtesp17'
ENV["LINKEDIN_SECRET"]='yN9ncr9Cwixl43qS'


ENV["SSH_KEY"]="eatme"

puts "Installation #{ENV["INSTALLATION"]} -- ASSET_HOST = #{ENV["ASSET_HOST"]}"
