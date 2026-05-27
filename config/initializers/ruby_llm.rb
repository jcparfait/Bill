RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY")
  config.openai_api_base = "https://models.inference.ai.azure.com"

  # important
  config.default_model = "gpt-4o"
end
