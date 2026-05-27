module CocktailsHelper
  def cocktail_image(cocktail)
    filename = cocktail.name.parameterize(separator: '_')
    image_path = "cocktails/#{filename}.jpg"

    begin
      image_tag(image_path, alt: cocktail.name, class: "cocktail-image")
    rescue
      content_tag(:div, "🍸", class: "cocktail-image-placeholder")
    end
  end
end
