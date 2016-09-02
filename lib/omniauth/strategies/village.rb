module OmniAuth
  module Strategies
    class Village < OmniAuth::Strategies::OAuth2
      
      option :name, :village

      option :client_options, {
        site: ENV["OAUTH_VILLAGE_SERVER"],
        authorize_path: "/oauth/authorize"
      }
      
      option :scope, 'public post_projects'

      uid do
        raw_info["id"]
      end

      info do
        {name: raw_info["login"], email: raw_info["email"]}
      end


      def raw_info
        @raw_info ||= access_token.get('/api/user').parsed
        rescue ::Errno::ETIMEDOUT
          raise ::Timeout::Error
      end
      
    end
  end
end