# frozen_string_literal: true

module Settings
  module SessionsHelper
    # Return a readable description of the device behind a user agent.
    #
    # @param user_agent [String, nil] The raw user agent of the request.
    # @return [String] The browser, full version, and platform when they are known.
    def device_description(user_agent)
      browser = Browser.new(user_agent)

      if browser.unknown?
        t("settings.sessions.index.unknown_device")
      elsif browser.platform.unknown?
        "#{browser.name} #{browser.full_version}"
      else
        t(
          "settings.sessions.index.device",
          browser:  "#{browser.name} #{browser.full_version}",
          platform: browser.platform.name.delete_prefix("Generic ")
        )
      end
    end
  end
end
