require 'omniauth-twitter'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, 'wftV4JUJk8RVjEryKa9Hw', 'vVQ0WbZKAHIHTQMXIS2agvaI36ccQrPlKNMlcK7uTo'
end