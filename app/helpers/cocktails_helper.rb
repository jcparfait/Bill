module CocktailsHelper
  def cocktail_image(cocktail)
    filename = cocktail.name.parameterize
    image_path = "cocktails/#{filename}.jpg"

    image_tag(image_path, alt: cocktail.name, class: "cocktail-image")
  rescue StandardError
    content_tag(:div, "🍸", class: "cocktail-image-placeholder")
  end
end
