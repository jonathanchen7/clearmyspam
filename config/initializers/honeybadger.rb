Honeybadger.configure do |config|
  config.exceptions.ignore += ["ApplicationJob::RetryError"]
end
