require 'line/bot'
require 'net/http' 
require 'uri'
require "json" 

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end

    reply_message = {
      type: 'text',
      text: "違います。"
    }
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          #message from user
          user_message = {
            type: 'text',
            text: event.message['text']
          }
          
          #reply to user
          if user_message[:text].match(/^http(s|):\/\/.*\.(png|jpg|gif)$/)
            #Using WATSON API for image recognition
            puts "-------------------------------"
            puts system("curl -u \"apikey:mJKpbO7JGGOL1QyAIrDsSPA0gpURtcTHarLRPVR6gFB0\" \
            \"https://gateway.watsonplatform.net/visual-recognition/api/v3/classify?\
            url=https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Shoyu_ramen%2C_at_Kasukabe_Station_%282014.05.05%29_2.jpg/1920px-Shoyu_ramen%2C_at_Kasukabe_Station_%282014.05.05%29_2.jpg\
            &version=2018-03-19\"")
            #puts api_result_get
            puts "-------------------------------"
            #api_result_json = JSON.parse(api_result_get)
            #reply_message = {
            #  type: 'text',
            #  text: "この画像のカテゴリーは" + api_result_json["images"][0]["classifiers"][0]["classes"][0]["class"] + \
            #  "で、類似度は" + (api_result_json["images"][0]["classifiers"][0]["classes"][0]["score"].to_f*100).to_s + "%です。"
            #}
            #puts api_result_json[:text] 
          end
          

          
        client.reply_message(event['replyToken'], reply_message)
        end
      end
    }
    head :ok
  end
end
