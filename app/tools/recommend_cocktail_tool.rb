require "open-uri"
require "json"
require "cgi"

class RecommendCocktailTool < RubyLLM::Tool
  description "Searches a real cocktail from TheCocktailDB by name and prepares it as a recommendation for the current chat."

  param :cocktail_name,
        desc: "The name of the cocktail to search for, for example Mojito, Margarita, Negroni, Daiquiri, Old Fashioned."

  param :mood,
        desc: "A short French description of the user's mood or need."

  def initialize(user:, chat:)
    @user = user
    @chat = chat
  end

  def execute(cocktail_name:, mood:)
    Rails.logger.info "Bill cocktail search: #{cocktail_name} / #{mood}"

    api_cocktail = fetch_cocktail(cocktail_name)

    if api_cocktail.nil?
      Rails.logger.warn "No cocktail found for #{cocktail_name}"
      return { error: "No cocktail found for #{cocktail_name}" }
    end

    cocktail = Cocktail.find_by(
      user: @user,
      external_id: api_cocktail["idDrink"]
    )

    status = "reused"

    if cocktail.nil?
      cocktail = Cocktail.create!(
        user: @user,
        external_id: api_cocktail["idDrink"],
        name: api_cocktail["strDrink"],
        image_url: api_cocktail["strDrinkThumb"],
        ingredients: format_ingredients(api_cocktail),
        recipe: api_cocktail["strInstructions"].to_s.strip,
        mood: mood,
        saved: false
      )

      status = "created"
    end

    {
      status: status,
      cocktail_id: cocktail.id,
      external_id: cocktail.external_id,
      name: cocktail.name,
      image_url: cocktail.image_url,
      ingredients: cocktail.ingredients,
      recipe: cocktail.recipe,
      mood: cocktail.mood
    }
  rescue StandardError => e
    Rails.logger.error "Bill cocktail tool error: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")

    { error: e.message }
  end

  private

  def fetch_cocktail(cocktail_name)
    encoded_name = CGI.escape(cocktail_name)
    url = "https://www.thecocktaildb.com/api/json/v1/1/search.php?s=#{encoded_name}"

    Rails.logger.info "Fetching cocktail API: #{url}"

    response = URI.open(url).read
    data = JSON.parse(response)
    drinks = data["drinks"] || []

    exact_match = drinks.find { |drink| drink["strDrink"].to_s.downcase == cocktail_name.to_s.downcase }
    exact_match || drinks.first
  end

  def format_ingredients(api_cocktail)
    ingredients = []

    (1..15).each do |index|
      ingredient = api_cocktail["strIngredient#{index}"]
      measure = api_cocktail["strMeasure#{index}"]

      next if ingredient.blank?

      line = if measure.present?
               "#{measure.strip} #{ingredient.strip}"
             else
               ingredient.strip
             end

      ingredients << "- #{line}"
    end

    ingredients.join("\n")
  end
end
