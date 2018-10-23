require 'line/bot'
require 'net/http' 
require 'uri'
require "json" 
require 'faraday'


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
            uri_image = 'https://gateway.watsonplatform.net/visual-recognition/api/v3/classify?url=' + user_message[:text] +'&version=2018-03-19'
            connection_watson_api = Faraday::Connection.new(:url => uri_image) do |builder|
                builder.use Faraday::Request::UrlEncoded
                builder.use Faraday::Request::BasicAuthentication, "apikey", "mJKpbO7JGGOL1QyAIrDsSPA0gpURtcTHarLRPVR6gFB0"
                builder.use Faraday::Response::Logger
                builder.use Faraday::Adapter::NetHttp                
            end
            response_from_watson_api_text = connection_watson_api.get 
            response_from_watson_api_json = JSON.parse(response_from_watson_api_text.body)
            reply_message = {
              type: 'text',
              text: "この画像のカテゴリーは" + response_from_watson_api_json["images"][0]["classifiers"][0]["classes"][0]["class"] + \
              "で、類似度は" + (response_from_watson_api_json["images"][0]["classifiers"][0]["classes"][0]["score"].to_f*100).to_s + "%です。"
            } 
          end          
        end
        client.reply_message(event['replyToken'], reply_message)
      end
    }
    head :ok
  end
end


