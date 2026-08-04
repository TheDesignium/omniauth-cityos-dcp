# frozen_string_literal: true

require "cgi"
require "securerandom"
require "uri"
require "omniauth-oauth2"

require_relative 'omniauth/cityos_dcp_login/version'
require_relative 'omniauth/cityos_dcp_login/error'
require_relative 'omniauth/strategies/cityos_dcp_login'
