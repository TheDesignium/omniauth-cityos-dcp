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

      initializer 'omniauth.cityos_dcp_login.check_decidim_version' do
        if defined?(Decidim) && Gem::Version.new(Decidim.version) >= Gem::Version.new("0.28.0")
          Rails.logger.warn "WARNING: You are using OmniAuth::CityosDcpLogin with Decidim #{Decidim.version}. This version of the plugin is designed for Decidim ~> 0.27.0."
          Rails.logger.warn "Please check for updates or contact the plugin maintainer for a version compatible with Decidim #{Decidim.version}."
          
          # オプション: 管理者に通知を送る
          if defined?(Decidim::EventsManager)
            Decidim::EventsManager.publish(
              event: "decidim.events.omniauth_cityos_dcp_login.version_mismatch",
              event_class: Decidim::Events::SimpleEvent,
              resource: Decidim::Core::Engine,
              affected_users: Decidim::User.where(admin: true),
              extra: {
                message: "OmniAuth::CityosDcpLogin may not be compatible with the current Decidim version (#{Decidim.version}). Please check for updates."
              }
            )
          end
        end
      end

      # **アイコン登録**
      initializer 'omniauth.cityos_dcp_login.register_icons' do
        ActiveSupport.on_load(:after_initialize) do
          if defined?(Decidim.icons)
            Decidim.icons.register(name: "facebook", icon: "facebook-fill", category: "system", description: "", engine: :core)
            Decidim.icons.register(name: "x", icon: "x-fill", category: "system", description: "", engine: :core)
            Decidim.icons.register(name: "google", icon: "google-fill", category: "system", description: "", engine: :core)
          else
            Rails.logger.warn "Decidim.icons is not defined. Unable to register custom icons."
          end
        end
      end

      # Require the strategy
      require_relative '../strategies/cityos_dcp_login'

      # Require the Railtie to load the initializer
      require_relative 'railtie'
    end
  end
end