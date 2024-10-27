# frozen_string_literal: true

module OmniAuth
    module Strategies
    class CityosDcpLogin < OmniAuth::Strategies::OAuth2
        class AgreementRequiredError < StandardError; end
        option :name, 'cityos_dcp_login'

        option state: SecureRandom.hex(24)
        option :pkce, true

        SRF_GUARD_COOKIE_NAME = 'xsrf_guard'.freeze

        uid { raw_info["user_id"] }

        info do
            {
                user_id: raw_info['user_id'],
                email: raw_info["user_email"],
                name: raw_info["nickname"]
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

            if cookie_store?
                super
            end

            error = request.params["error_reason"] || request.params["error"]

            # エラーチェック
            if error
                fail!(error, CallbackError.new(request.params["error"], request.params["error_description"] || request.params["error_reason"], request.params["error_uri"]))
            elsif request.params['code']
                super
            elsif request.cookies[SRF_GUARD_COOKIE_NAME] && session[:csrf_guard]

                # オプトインフローでのCSRFチェック
                handle_opt_in_flow_with_csrf_check
                OmniAuth::Strategy.instance_method(:callback_phase).bind(self).call
            else
                # 期待されるパラメータがない場合のエラー処理
                fail!(:invalid_request, CallbackError.new(:invalid_request, "Invalid request in callback"))
            end
        rescue AgreementRequiredError => e
            if cookie_store?
                return redirect(e.message)
            end
            return redirect_with_csrf_token(e.message)
        rescue ::OAuth2::Error, CallbackError => e
            fail!(:invalid_credentials, e)
        rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
            fail!(:timeout, e)
        rescue ::SocketError => e
            fail!(:failed_to_connect, e)
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
                                                    userId: "1",
                                                    nickname: "1",
                                                    userEmail: "1",
                                                }
                                             }.to_json
                                            ).parsed
            session["access_token"] = access_token.token
            if @id_token_payload.agreeFlg == "0" then
                redirect_url = nil
                if cookie_store?
                    redirect_url = agreement_callback_url
                else
                    redirect_url = callback_url
                end
                agreement_url = "https://#{options.optin_url}?serviceId=#{options.service_id}&redirectUrl=#{CGI.escape(redirect_url)}"
                raise AgreementRequiredError, agreement_url
            else
                Rails.logger.info("token:#{@id_token_payload.inspect}")
                @id_token_payload
            end
        end

        def agreement_callback_url
            full_host + "/users/sign_in"
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

        def handle_opt_in_flow_with_csrf_check
            csrf_token = request.cookies[SRF_GUARD_COOKIE_NAME]

            if csrf_token.nil? || csrf_token != session[:csrf_guard]
                fail!(:csrf_detected, CallbackError.new(:csrf_detected, "CSRF detected"))
            else
                # CSRFトークンが一致した場合、セッションとクッキーからCSRFトークンを削除
                session.delete(:csrf_guard)
                session.delete("omniauth.pkce.verifier")
                request.cookies.delete(SRF_GUARD_COOKIE_NAME)
                # オプトイン承認後に必要な処理を行う
                request.params['state'] = csrf_token
                session['omniauth.state'] = csrf_token
                Rails.logger.debug "Current sessions: #{session.to_hash.inspect}"
                self.access_token = build_access_token_class session["access_token"]
            end
        end

        def redirect_with_csrf_token(uri, options = {})
            r = Rack::Response.new

            # URIからパスを抽出
            begin
                parsed_uri = URI(uri)
                path = parsed_uri.path.empty? ? '/' : parsed_uri.path
                domain = extract_domain(parsed_uri.host)
              rescue URI::InvalidURIError
                # 無効なURIの場合のエラー処理
                Rails.logger.error "Invalid URI provided: #{uri}"
                raise ArgumentError, "Invalid URI provided: #{uri}"
              end


            csrf_token = SecureRandom.urlsafe_base64(32)
            session[:csrf_guard] = csrf_token

            r.set_cookie(SRF_GUARD_COOKIE_NAME, {
                value: csrf_token,
                expires: 5.minutes.from_now,
                secure: true,
                http_only: true,
                same_site: :none  # クロスサイトリクエストを許可する場合
            })

            Rails.logger.debug "Cookies after setting:"
            Rails.logger.debug r.headers["Set-Cookie"]

            if options[:iframe]
                r.write("<script type='text/javascript' charset='utf-8'>top.location.href = '#{uri.to_json}';</script>")
            else
                # r.write("Redirecting to #{uri}...")
                r.redirect(uri)
            end

            r.finish
        end

        def extract_domain(host)
            return nil if host.nil?

            parts = host.split('.')
            return host if parts.length <= 2

            # サブドメインを除去し、メインドメインとTLDを返す
            parts.slice(-2, 2).join('.')
        end

        def build_access_token_class(existing_token)
            ::OAuth2::AccessToken.new(
            client,
            existing_token
          )
        end

        def sanitize_nickname(nickname)
            # 正規表現パターン: 文字、数字、'-' および '_' のみを許可
            valid_pattern = /^[a-zA-Z0-9\-_]+$/

            if nickname.present? && nickname.match?(valid_pattern)
              nickname
            else
              # ランダムな8文字の英数字を生成
              SecureRandom.alphanumeric(8)
            end
        end

        def detect_session_store
            return false unless defined?(Rails)
            return false unless Rails.application
            
            begin
              store = Rails.application.config.session_store
              return store if store
              false
            rescue
              false
            end
        end
          
        def cookie_store?
            store = detect_session_store
            return true unless store  # セッションが検出できない場合はcookie扱い
            store.to_s.include?('CookieStore')
        end
    end
    end
end
