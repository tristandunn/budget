# frozen_string_literal: true

# Define an application-wide content security policy.
#
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.base_uri        :none
    policy.connect_src     :self
    policy.default_src     :self
    policy.font_src        :self
    policy.form_action     :self
    policy.frame_ancestors :none
    policy.frame_src       :none
    policy.img_src         :self, :data
    policy.manifest_src    :self
    policy.object_src      :none
    policy.script_src      :self
    policy.style_src       :self
  end

  config.content_security_policy_nonce_generator  = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w(script-src style-src)
end
