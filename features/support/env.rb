# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.
require 'rubygems'
require 'simplecov'

SimpleCov.start 'rails'

require 'fabrication'
require 'cucumber/rails'
require 'sidekiq/testing/inline'
Capybara.default_selector = :css
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
require 'cucumber/rspec/doubles'
ActionController::Base.allow_rescue = false