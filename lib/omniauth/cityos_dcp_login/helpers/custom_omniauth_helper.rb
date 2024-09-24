module OmniAuth
  module CityosDcpLogin
    module Helpers
      module CustomOmniauthHelper
        def normalize_provider_name(provider)
          # return 'helper override from CityosDcpLogin'
          return "x" if provider == :twitter

          provider.to_s.split("_").first
        end

        def oauth_icon(provider)
          # Your custom implementation
          info = current_organization.enabled_omniauth_providers[provider.to_sym]

          if info
            icon_path = info[:icon_path]
            return external_icon(icon_path) if icon_path

            name = info[:icon]
          end

          name ||= normalize_provider_name(provider)
          icon(name)
        end

        def provider_name(provider)
          # Your custom implementation
          provider.to_s.gsub(/_|-/, " ").camelize
        end
      end
    end
  end
end