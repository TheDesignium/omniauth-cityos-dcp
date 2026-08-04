# frozen_string_literal: true

RSpec.describe OmniAuth::Strategies::CityosDcpLogin do
  subject(:strategy) do
    described_class.new(
      {},
      client_id: "client-id",
      client_secret: "client-secret",
      policy: "policy",
      optin_url: "https://login.example.com/opt-in",
      opt_api_base_url: "api.example.com",
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

  it "delegates the cookie-store callback exactly once" do
    allow(strategy).to receive(:oauth2_callback_phase).and_return(:callback_response)

    expect(strategy.callback_phase).to eq(:callback_response)
    expect(strategy).to have_received(:oauth2_callback_phase).once
  end

  it "supports a host-provided non-cookie session setting" do
    strategy.options.cookie_store = false

    expect(strategy.send(:cookie_store?)).to be(false)
  end

  it "requests only the CityOS profile fields used by the auth hash" do
    payload = double("payload", agreeFlg: "1")
    response = double("response", parsed: payload)
    access_token = double("access token", token: "secret-token")
    client = double("client")

    allow(strategy).to receive(:access_token).and_return(access_token)
    allow(strategy).to receive(:client).and_return(client)
    allow(strategy).to receive(:session).and_return({})
    expect(client).to receive(:request).with(
      :post,
      "https://api.example.com/api/v2/users/retrieve",
      hash_including(
        body: {
          retrieveItem: {
            userId: "1",
            nickname: "1"
          }
        }.to_json
      )
    ).and_return(response)

    expect(strategy.send(:user_info_opt)).to eq(payload)
  end
end
