# encoding: UTF-8

require 'rack/mock'
require 'middleman-core/rack'

Given /^a clean server$/ do
  @initialize_commands = []
end

Given /^"([^\"]*)" feature is "([^\"]*)"$/ do |feature, state|
  @initialize_commands ||= []

  if state == 'enabled'
    @initialize_commands << lambda { activate(feature.to_sym) }
  end
end

Given /^"([^\"]*)" feature is "enabled" with "([^\"]*)"$/ do |feature, options_str|
  @initialize_commands ||= []

  options = eval("{#{options_str}}")

  @initialize_commands << lambda { activate(feature.to_sym, options) }
end

Given /^"([^\"]*)" is set to "([^\"]*)"$/ do |variable, value|
  @initialize_commands ||= []
  @initialize_commands << lambda {
    config[variable.to_sym] = value
  }
end

Given /^the Server is running$/ do
  root_dir = File.expand_path(current_dir)


  if File.exists?(File.join(root_dir, 'source'))
    ENV['MM_SOURCE'] = 'source'
  else
    ENV['MM_SOURCE'] = ''
  end

  ENV['MM_ROOT'] = root_dir

  initialize_commands = @initialize_commands || []

  in_current_dir do
    @server_inst = ::Middleman::Application.new do
      config[:watcher_disable] = true
      config[:show_exceptions] = false

      initialize_commands.each do |p|
        instance_exec(&p)
      end
    end
  end

  rack = ::Middleman::Rack.new(@server_inst)
  @browser = ::Rack::MockRequest.new(rack.to_app)
end

Given /^the Server is running at "([^\"]*)"$/ do |app_path|
  step %Q{a fixture app "#{app_path}"}
  step %Q{the Server is running}
end

Given /^a template named "([^\"]*)" with:$/ do |name, string|
  step %Q{a file named "source/#{name}" with:}, string
end

When /^I go to "([^\"]*)"$/ do |url|
  in_current_dir do
    @last_response = @browser.get(URI.escape(url))
  end
end

Then /^going to "([^\"]*)" should not raise an exception$/ do |url|
  in_current_dir do
    last_response = nil
    expect {
      last_response = @browser.get(URI.escape(url))
    }.to_not raise_error
    @last_response = last_response
  end
end

Then /^the content type should be "([^\"]*)"$/ do |expected|
  in_current_dir do
    expect(@last_response.content_type).to start_with(expected)
  end
end

Then /^I should see "([^\"]*)"$/ do |expected|
  in_current_dir do
    expect(@last_response.body).to include(expected)
  end
end

Then /^I should see '([^\']*)'$/ do |expected|
  in_current_dir do
    expect(@last_response.body).to include(expected)
  end
end

Then /^I should see:$/ do |expected|
  in_current_dir do
    expect(@last_response.body).to include(expected)
  end
end

Then /^I should not see "([^\"]*)"$/ do |expected|
  in_current_dir do
    expect(@last_response.body).to_not include(expected)
  end
end

Then /^I should see content matching %r{(.*)}$/ do |expected|
  in_current_dir do
    expect(@last_response.body).to match(expected)
  end
end

Then /^I should not see content matching %r{(.*)}$/ do |expected|
  in_current_dir do
    expect(@last_response.body).to_not match(expected)
  end
end

Then /^I should not see:$/ do |expected|
  in_current_dir do
    expect(@browser.last_response.body).to_not include(expected.chomp)
  end
end

Then /^the status code should be "([^\"]*)"$/ do |expected|
  in_current_dir do
    expect(@browser.last_response.status).to eq expected.to_i
  end
end

Then /^I should see "([^\"]*)" lines$/ do |lines|
  in_current_dir do
    expect(@last_response.body.chomp.split($/).length).to eq(lines.to_i)
  end
end
