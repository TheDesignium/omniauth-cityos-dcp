# frozen_string_literal: true

require_relative "lib/omniauth/cityos_dcp_login/version"

Gem::Specification.new do |spec|
  spec.name = "omniauth-cityos-dcp"
  spec.version = OmniAuth::CityosDcpLogin::VERSION
  spec.authors = ["Yousan_O"]
  spec.email = ["yousan@l2tp.org"]

  spec.summary = "OmniAuth Strategy for cityOS DCP Login"
  spec.description = "OmniAuth Strategy for cityOS DCP Login"
  spec.homepage = "https://example.com"
  # spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "https://example.com"
  # spec.metadata["changelog_uri"] = "https://example.com"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir[
    'lib/**/*',
    'Rakefile',
    'README.md'
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'omniauth-oauth2'

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'

  # decidimのバージョンを27系のみとする
  spec.add_dependency "decidim", ">= 0.28.0"

end
