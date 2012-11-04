require 'omniauth-twitter'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, 'jV8N28AuBGPnpcnUEkfplg', 'mcFXhFskgUdS7259hk2fS1VQCg46YIVjftAJs28MuE'
end