require 'line/bot'

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

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          #message from user
          message = {
            type: 'text',
            text: event.message['text']
          }
          #reply to user
          if event.message['text'] == "gifteeのeチケットシェア率は？" then
            reply_message = {
              type: 'text',
              text: "80%!"
            }   
          else
            reply_message = {
              type: 'text',
              text: "わかりません。"
            }
          end
          
          client.reply_message(event['replyToken'], reply_message)
        when Line::Bot::Event::MessageType::Image
          puts event.message['originalContentUrl']


          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        else
          #reply to user
          reply_message = {
            type: 'text',
            text: "わかりません。"
          }
    client.reply_message(event['replyToken'], reply_message)    
          
        end
      end
    }
    head :ok
  end
end
