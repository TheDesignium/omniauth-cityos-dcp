# frozen_string_literal: true

require "minitest/autorun"

class StandaloneContractTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_entrypoint_loads_without_decidim
    output = IO.popen(
      [RbConfig.ruby, "-I#{File.join(ROOT, "lib")}", "-e", <<~'RUBY'], &:read
        require "omniauth-cityos-dcp"
        abort "wrong version" unless OmniAuth::CityosDcpLogin::VERSION == "1.5.1"
        abort "strategy missing" unless OmniAuth::Strategies::CityosDcpLogin
      RUBY
    )

    assert_equal "", output
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
