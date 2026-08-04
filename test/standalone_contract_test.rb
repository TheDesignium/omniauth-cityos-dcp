# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class StandaloneContractTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_entrypoint_loads_without_decidim
    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-I#{File.join(ROOT, "lib")}",
      "-e",
      <<~'RUBY'
        require "omniauth-cityos-dcp"
        abort "wrong version" unless OmniAuth::CityosDcpLogin::VERSION == "1.5.2"
        abort "strategy missing" unless OmniAuth::Strategies::CityosDcpLogin
      RUBY
    )

    assert status.success?, stderr
    assert_equal "", stdout
    assert_equal "", stderr
  end

  def test_runtime_helpers_do_not_require_rails_or_active_support
    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-I#{File.join(ROOT, "lib")}",
      "-e",
      <<~'RUBY'
        require "omniauth-cityos-dcp"
        abort "Rails was loaded" if defined?(Rails)

        strategy = OmniAuth::Strategies::CityosDcpLogin.new({}, cookie_store: false)
        abort "cookie_store option ignored" if strategy.send(:cookie_store?)
        abort "nickname helper failed" unless strategy.send(:sanitize_nickname, "cityos_user") == "cityos_user"

        env = Rack::MockRequest.env_for("/")
        env["rack.session"] = {}
        strategy.instance_variable_set(:@env, env)
        response = strategy.send(:redirect_with_csrf_token, "https://login.example.com/opt-in")
        abort "redirect helper failed" unless response[0] == 302
        abort "csrf cookie missing" unless response[1]["set-cookie"].include?("xsrf_guard")
      RUBY
    )

    assert status.success?, stderr
    assert_equal "", stdout
    assert_equal "", stderr
  end

  def test_gemspec_has_no_host_application_dependency
    gemspec = File.read(File.join(ROOT, "omniauth-cityos-dcp.gemspec"))

    refute_includes gemspec, 'spec.add_dependency "decidim"'
    assert_includes gemspec, 'spec.add_dependency \'omniauth-oauth2\''
  end

  def test_gem_does_not_ship_decidim_application_files
    refute File.exist?(File.join(ROOT, "lib/omniauth/cityos_dcp_login/engine.rb"))
    refute File.exist?(File.join(ROOT, "lib/omniauth/cityos_dcp_login/railtie.rb"))
    refute File.exist?(File.join(ROOT, "lib/omniauth/cityos_dcp_login/config/secrets.yml"))
  end
end
