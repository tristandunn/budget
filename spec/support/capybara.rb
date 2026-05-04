# frozen_string_literal: true

require "capybara"

Capybara.server = :puma, { Silent: true }
Capybara.javascript_driver = :selenium_chrome_headless_reduced_motion

Capybara.register_driver :selenium_chrome_headless_reduced_motion do |app|
  driver = Capybara.drivers[:selenium_chrome_headless].call(app)
  driver.options[:options].add_argument("--force-prefers-reduced-motion")
  driver
end
