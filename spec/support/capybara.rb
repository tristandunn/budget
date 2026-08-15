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

RSpec.configure do |config|
  config.before(:each, type: :feature) do |example|
    if example.metadata[:js]
      if example.metadata[:mobile]
        Capybara.current_driver = :selenium_chrome_headless_reduced_motion_mobile
      end
    elsif example.metadata[:mobile]
      page.driver.header("User-Agent", UserAgents::MOBILE)
    else
      page.driver.header("User-Agent", UserAgents::DESKTOP)
    end
  end
end
