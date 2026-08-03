# frozen_string_literal: true

require "minitest/autorun"

class DecidimV030ContractTest < Minitest::Test
  def test_entrypoint_only_loads_the_strategy
    source = File.read(entrypoint_path)

    assert_includes source, "require_relative 'omniauth/strategies/cityos_dcp_login'"
    refute_includes source, "require_relative 'omniauth/cityos_dcp_login/engine'"
  end

  def test_gem_does_not_override_host_application_ui_or_configuration
    refute File.exist?(File.join(repository_root, "lib/omniauth/cityos_dcp_login/engine.rb"))
    refute File.exist?(File.join(repository_root, "lib/omniauth/cityos_dcp_login/railtie.rb"))
    refute File.exist?(File.join(repository_root, "lib/omniauth/cityos_dcp_login/helpers/provider_name_helper.rb"))
    refute File.exist?(File.join(repository_root, "lib/omniauth/cityos_dcp_login/config/secrets.yml"))
  end

  def test_gemspec_supports_decidim_v030_only
    source = File.read(gemspec_path)

    assert_includes source, 'spec.add_dependency "decidim", "~> 0.30.0"'
    refute_includes source, "app/**/*"
  end

  def test_host_application_owns_registration_and_uses_a_boolean_default
    initializer = File.read(host_path("config/initializers/omniauth_cityos_dcp.rb"))
    secrets = File.read(host_path("config/secrets.yml"))

    assert_includes initializer, "Rails.application.config.middleware.use OmniAuth::Builder"
    assert_includes initializer, ":cityos_dcp_login,"
    assert_includes secrets, "cityos_dcp_login:\n      enabled: false"
    assert_includes secrets, "label: <%= ENV[\"OMNIAUTH_CITYOS_DCP_LABEL\"] %>"
    assert_includes secrets, "icon_path: <%= ENV[\"OMNIAUTH_CITYOS_DCP_ICON_PATH\"] %>"
    locale = File.read(host_path("config/locales/cityos_dcp_login.ja.yml"))
    assert_includes locale, "label: ログインボタン表示名"
    assert_includes locale, "icon_path: アイコンURL"
    refute_includes initializer, "Decidim::OmniauthHelper"
  end

  def test_host_view_renders_cityos_label_and_a_registered_icon
    view = File.read(host_path("app/views/decidim/devise/shared/_omniauth_buttons.html.erb"))

    assert_includes view, "provider_config[:label].presence || provider_name(provider_key)"
    assert_includes view, "provider_config[:icon_path].presence"
    assert_includes view, "external_icon(provider_icon_path) if provider_icon_path"
    assert_includes view, "provider_key == :cityos_dcp_login"
    refute_includes view, "account-circle-line"
  end

  def test_host_styles_keep_the_cityos_label_visible
    styles = File.read(host_path("app/packs/stylesheets/decidim/cfj/login.scss"))

    assert_includes styles, ".login__omniauth-button--cityos span"
    assert_includes styles, "display: inline !important"
  end

  private

  def repository_root
    File.expand_path("..", __dir__)
  end

  def entrypoint_path
    File.join(repository_root, "lib/omniauth-cityos-dcp.rb")
  end

  def gemspec_path
    File.join(repository_root, "omniauth-cityos-dcp.gemspec")
  end

  def host_path(path)
    File.expand_path("../../../#{path}", __dir__)
  end
end
