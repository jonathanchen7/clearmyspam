require "net/http"
require "uri"
require "json"

module Facebook
  module EventType
    ALL = [
      Purchase = "Purchase",
      InitiateCheckout = "InitiateCheckout",
      StartTrial = "StartTrial",
      ViewContent = "ViewContent",
      PageView = "PageView"
    ].freeze
  end

  class PixelClient
    FACEBOOK_API_VERSION = "v23.0"
    FACEBOOK_PIXEL_ID = "2795626927301766"

    CONVERSIONS_API_URL = "https://graph.facebook.com/#{FACEBOOK_API_VERSION}/#{FACEBOOK_PIXEL_ID}/events"

    attr_reader :user, :source_url, :user_agent, :ip_address, :fbc, :fbp

    class << self
      def from_request(user, request)
        new(user,
          source_url: request.url,
          user_agent: request.user_agent,
          ip_address: request.remote_ip,
          fbc: request.cookies["_fbc"],
          fbp: request.cookies["_fbp"]
        )
      end
    end

    def initialize(user, source_url: "https://clearmyspam.com", user_agent: "Unknown", ip_address: nil, fbc: nil, fbp: nil)
      @user = user
      @source_url = source_url
      @user_agent = user_agent
      @ip_address = ip_address
      @fbc = fbc
      @fbp = fbp
    end

    def track_event(event_type, base_data: {}, additional_user_data: {}, custom_data: {})
      return unless Rails.configuration.enable_facebook_pixel

      unless EventType::ALL.include?(event_type)
        Rails.logger.error("facebook.pixel_client.invalid_event_type: #{event_type}")
        return
      end

      begin
        Rails.logger.info("facebook.pixel_client.track_event: #{event_type}")
        result = make_request(event_type, base_data, additional_user_data, custom_data)
        Rails.logger.info("facebook.pixel_client.result: #{result.body}")
      rescue => e
        Rails.logger.error("facebook.pixel_client.error: #{e.message}")
      end
    end

    private

    def make_request(event_type, base_data, additional_user_data, custom_data)
      uri = URI(CONVERSIONS_API_URL)
      uri.query = URI.encode_www_form({
        access_token: Rails.application.credentials.facebook.conversions_api_key
      })

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = data_payload(event_type, base_data, additional_user_data, custom_data).to_json

      response = http.request(request)
      response
    end

    def data_payload(event_type, base_data, additional_user_data, custom_data)
      {
        data: [
          {
            event_name: event_type,
            event_time: Time.now.to_i,
            action_source: "website",
            event_source_url: source_url,
            user_data: {
              em: hash(user.email.downcase),
              external_id: hash(user.id),
              client_ip_address: ip_address,
              client_user_agent: user_agent,
              fbc: fbc,
              fbp: fbp
            }.merge(additional_user_data),
            custom_data: custom_data
          }.merge(base_data)
        ]
      }
    end

    def hash(string)
      Digest::SHA256.hexdigest(string)
    end
  end
end
