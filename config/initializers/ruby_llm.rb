RubyLLM.configure do |config|
  if ENV["GITHUB_TOKEN"].present?
    config.openai_api_key = ENV.fetch("GITHUB_TOKEN")
    config.openai_api_base = ENV.fetch("GITHUB_MODELS_API_BASE", "https://models.inference.ai.azure.com")
    config.default_model = ENV.fetch("GITHUB_MODELS_MODEL", "gpt-4o")
  elsif ENV["OPENAI_API_KEY"].present?
    config.openai_api_key = ENV.fetch("OPENAI_API_KEY")
    config.default_model = ENV.fetch("OPENAI_MODEL", "gpt-4o")
  else
    raise KeyError, "Missing GITHUB_TOKEN or OPENAI_API_KEY. Set GITHUB_TOKEN for GitHub Models, or OPENAI_API_KEY for OpenAI."
  end
end
