require "open-uri"
require "json"
require "cgi"

class RecommendCocktailTool < RubyLLM::Tool
  description "Searches a real cocktail from TheCocktailDB by name, saves it for the current user, and links it to the current chat."

  param :cocktail_name,
        desc: "The name of the cocktail to search for, for example Mojito, Margarita, Negroni, Daiquiri, Old Fashioned."
  param :mood, desc: "A short French description of the user's mood or need."

  def initialize(user:, chat:)
    @user = user
    @chat = chat
  end

  def execute(cocktail_name:, mood:)
    api_cocktail = fetch_cocktail(cocktail_name)

    return { error: "No cocktail found for #{cocktail_name}" } if api_cocktail.nil?

    ingredients = translate_to_french(
      format_ingredients(api_cocktail),
      "liste d'ingrédients"
    )

    recipe = translate_to_french(
      api_cocktail["strInstructions"],
      "recette de cocktail"
    )

    cocktail = Cocktail.create!(
      user: @user,
      external_id: api_cocktail["idDrink"],
      name: api_cocktail["strDrink"],
      image_url: api_cocktail["strDrinkThumb"],
      ingredients: ingredients,
      recipe: recipe,
      mood: mood
    )

    @chat.update!(cocktail: cocktail)

    {
      status: "saved",
      cocktail_id: cocktail.id,
      external_id: cocktail.external_id,
      name: cocktail.name,
      image_url: cocktail.image_url,
      ingredients: cocktail.ingredients,
      recipe: cocktail.recipe,
      mood: cocktail.mood
    }
  rescue StandardError => e
    { error: e.message }
  end

  private

  def fetch_cocktail(cocktail_name)
    encoded_name = CGI.escape(cocktail_name)
    url = "https://www.thecocktaildb.com/api/json/v1/1/search.php?s=#{encoded_name}"

    response = URI.open(url).read
    data = JSON.parse(response)

    data["drinks"]&.first
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

  def translate_to_french(text, content_type)
    prompt = <<~PROMPT
      Traduis fidèlement en français cette #{content_type}.

      Contraintes :
      - Ne rajoute aucune information.
      - Ne supprime aucune information.
      - Ne change pas les quantités.
      - Ne transforme pas la recette.
      - Garde les retours à la ligne.
      - Si le texte contient une liste avec des tirets, garde une liste avec des tirets.
      - Ne donne aucune explication.
      - Retourne uniquement la traduction française.

      Texte :
      #{text}
    PROMPT

    RubyLLM.chat.ask(prompt).content.strip
  end
end
