require 'active_support/core_ext/hash'

module OmniAuth
  module CityosDcpLogin
    class Engine < ::Rails::Engine
      isolate_namespace OmniAuth::CityosDcpLogin

      initializer 'omniauth.cityos_dcp_login.load_secrets' do |app|
        secrets_path = root.join('lib/omniauth/cityos_dcp_login/config/secrets.yml')
        if File.exist?(secrets_path)
          secrets = YAML.load_file(secrets_path)
          secrets = (secrets[Rails.env] || secrets['default']).deep_symbolize_keys
          if Rails.application.secrets.respond_to?(:[])
            Rails.application.secrets[:omniauth][:cityos_dcp_login] = secrets[:omniauth][:cityos_dcp_login]
          end
        end
      end

      initializer 'omniauth.cityos_dcp_login.helpers' do
        ActiveSupport.on_load(:action_controller) do
          Decidim::OmniauthHelper.prepend OmniAuth::CityosDcpLogin::Helpers::CustomOmniauthHelper
        end
      end

      initializer 'omniauth.cityos_dcp_login.append_view_paths', before: :set_autoload_paths do |app|
        app.config.paths['app/views'].unshift(root.join('lib/omniauth/cityos_dcp_login/views'))
        Rails.logger.debug "Append OmniAuth::CityosDcpLogin view path for override"
        Rails.logger.debug "View Paths: #{app.config.paths['app/views'].to_a.join(', ')}"
      end

      initializer 'omniauth.cityos_dcp_login.load_locales' do |app|
        I18n.load_path += Dir[root.join('lib/omniauth/cityos_dcp_login/config/locales/*.yml')]
      end


      # Require the strategy
      require_relative '../strategies/cityos_dcp_login'

      # Require the Railtie to load the initializer
      require_relative 'railtie'
    end
  end
end