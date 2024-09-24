# frozen_string_literal: true

module OmniAuth
    module Strategies
    class CityosDcpLogin < OmniAuth::Strategies::OAuth2
        class AgreementRequiredError < StandardError; end
        option :name, 'cityos_dcp_login'

        option state: SecureRandom.hex(24)
        option :pkce, true

        uid { raw_info["user_id"] }

        info do
            {
                nickname: raw_info["nickname"],
                email: raw_info["user_email"],
                name: raw_info["nickname"],
                first_name: raw_info["user_last_name"],
                last_name: raw_info["user_first_name"]
            }
        end

        def raw_info
            @raw_info ||= begin
                user_info_opt
            rescue AgreementRequiredError => e
                raise e
            end
        end

        def callback_phase
            super
        rescue AgreementRequiredError => e
            return redirect(e.message)
        end

        def setup_phase
            super
            options.client_options[:site] = site_url
            options.client_options[:authorize_url] = "https://#{options.authorization_url}/oauth2/v2.0/authorize"
            options.client_options[:token_url] = "https://#{options.authorization_url}/#{options.policy}/oauth2/v2.0/token"
        end

        private

        def authorize_params
            super.tap do |params|
                params[:client_id] = options.client_id
                params[:nonce] = SecureRandom.uuid
                session["omniauth.nonce"] = params[:nonce]
                params[:redirect_uri] = callback_url
                params[:p] = options.policy
                params[:response_type] = 'code'
                # params[:prompt] = 'login' # ログイン強制ではないので不要
            end
        end

        def token_params
            # 親クラスの token_params メソッドの結果を取得し、新しいキーと値をマージ
            super.merge({
                client_id: options.client_id,
                client_secret: options.client_secret,
                grant_type: 'authorization_code',
                scope: options.scope,
                # p: options.policy
            })
        end

        def callback_url
            full_host + script_name + callback_path
        end

        def user_info_opt
        @id_token_payload ||= client.request(:post, "https://#{options.opt_api_base_url}/api/v2/users/retrieve",
                                             headers: {
                                               Authorization: "Bearer "+access_token.token,
                                               'Content-Type': "application/json"
                                             },
                                             body: {
                                                retrieveItem: {
                                                    countryCode: "1",
                                                    userId: "1",
                                                    nickname: "1",
                                                    userEmail: "1",
                                                    userProfileImg: "1",
                                                    userLastName: "1",
                                                    userFirstName: "1",
                                                }
                                             }.to_json
                                            ).parsed
            if @id_token_payload.agreeFlg == "0" then
                agreement_url = "https://#{options.optin_url}?serviceId=#{options.service_id}&redirectUrl=#{CGI.escape(agreement_callback_url)}"
                raise AgreementRequiredError, agreement_url
            else
                Rails.logger.info("token:#{@id_token_payload.inspect}")
                @id_token_payload
            end
        end

        def agreement_callback_url
            full_host + "/users/sign_in?locale=ja"
        end

        def code_verifier
            @code_verifier ||= SecureRandom.hex(24)
        end

        def site_url
            url = options.optin_url
            parts = url.split('.com')
            return parts[0] + '.com' if parts.size > 1
            url
        end
    end
    end
end
