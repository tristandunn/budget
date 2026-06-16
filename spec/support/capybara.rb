# frozen_string_literal: true

require "capybara"

Capybara.server = :puma, { Silent: true }
Capybara.javascript_driver = :selenium_chrome_headless_reduced_motion

Capybara.register_driver :selenium_chrome_headless_reduced_motion do |app|
  driver = Capybara.drivers[:selenium_chrome_headless].call(app)
  driver.options[:options].add_argument("--force-prefers-reduced-motion")
  driver.options[:options].add_argument("--window-size=1470,840")
  driver
end

Capybara.register_driver :selenium_chrome_headless_reduced_motion_mobile do |app|
  driver = Capybara.drivers[:selenium_chrome_headless_reduced_motion].call(app)
  driver.options[:options].add_argument("--user-agent=#{UserAgents::MOBILE}")
  driver
end

# Feature specs default to a desktop User-Agent, so the desktop request variant
# renders. Tag a spec with `:mobile` to exercise the mobile variant instead,
# switching the Selenium driver or setting the rack-test header as appropriate.
RSpec.configure do |config|
  config.before(:each, :mobile) do |example|
    if example.metadata[:js]
      Capybara.current_driver = :selenium_chrome_headless_reduced_motion_mobile
    else
      page.driver.header("User-Agent", UserAgents::MOBILE)
    end
  end
end
