# frozen_string_literal: true

RSpec.describe OmniAuth::Strategies::CityosDcpLogin do
  subject(:strategy) do
    described_class.new(
      {},
      client_id: "client-id",
      client_secret: "client-secret",
      policy: "policy",
      optin_url: "https://login.example.com/opt-in",
      authorization_url: "login.example.com",
      scope: "openid"
    )
  end

  it "registers the CityOS provider name" do
    expect(strategy.options.name).to eq("cityos_dcp_login")
  end

  it "builds the CityOS authorization endpoint" do
    strategy.send(:setup_phase)

    expect(strategy.options.client_options[:site]).to eq("https://login.example.com")
    expect(strategy.options.client_options[:authorize_url]).to eq(
      "https://login.example.com/oauth2/v2.0/authorize"
    )
    expect(strategy.options.client_options[:token_url]).to eq(
      "https://login.example.com/policy/oauth2/v2.0/token"
    )
  end
end
