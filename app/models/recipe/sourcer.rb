require "open-uri"

class Recipe::Sourcer
  UA_STRING = "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

  def initialize(recipe)
    @recipe = recipe
  end

  def update_recipe_with_original_info
    strategy = decide_methodology
    data     = strategy.extract_all
  
    ActiveRecord::Base.transaction do
      # 1) Update the “canonical” metadata on RecipeSource
      @recipe.update!(
        original_title: data[:original_title],
        image_url:      data[:image_url],
        directions:     data[:directions],
        yield:          data[:yield_count],
        yield_unit:     data[:yield_unit]
      )
  
      # 2) For each user’s Recipe instance off that source,
      #    re-sync its ingredients
      @recipe.user_recipes.find_each do |recipe|
        recipe.recipe_ingredients.delete_all
        data[:raw_ingredients].each_with_index do |line, idx|
          parsed = IngredientParser.parse(line, data[:locale])

          # Find or create the canonical ingredient
          ingredient = Ingredient.find_or_create_by!(name: parsed[:normalized_name])
          # Track synonyms for locale-specific lookup
          ingredient.ingredient_synonyms.find_or_create_by!(
            locale: parsed[:locale],
            name:   parsed[:original_name]
          )
  
          # Create the join record with both original and base (metric) measurements
          recipe.recipe_ingredients.create!(
            ingredient:    ingredient,
            quantity:      parsed[:quantity],
            unit:          parsed[:unit],
            base_quantity: parsed[:base_quantity],
            base_unit:     parsed[:base_unit],
            measure_type:  parsed[:measure_type],
            notes:         parsed[:notes],
            position:      idx + 1
          )
        end
      end
    end
  end

  private

  def decide_methodology
    html = URI.open(@recipe.url, "User-Agent" => UA_STRING) { |f| f.read }
    doc  = Nokogiri::HTML(html)

    if (json_ld = extract_json_ld(doc)).present?
      ::Recipe::JsonLdStrategy.new(json_ld)
    elsif doc.at_css('[itemprop]')
      ::Recipe::MicrodataStrategy.new(doc)
    else
      ::Recipe::FallbackStrategy.new(doc)
    end
  end

  def extract_json_ld(doc)
    doc.css('script[type="application/ld+json"]').flat_map { |s|
      JSON.parse(s.text)
    } rescue []
    .find { |obj| obj["@type"]&.casecmp("Recipe")==0 }
  end
end


# class RecipeSource::Sourcer
#   UA_STRING = "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

#   def initialize(recipe_source)
#     @recipe_source = recipe_source
#   end

#   def update_recipe_source_with_original_info
#     strategy = decide_methodology
#     data     = strategy.extract_all

#     @recipe_source.update!(data.slice(
#       :original_title, :image_url,
#       :ingredients, :directions, :yield
#     ))
#   end

#   private

#   def decide_methodology
#     html = URI.open(@recipe_source.url, "User-Agent" => UA_STRING) { |f| f.read }
#     doc  = Nokogiri::HTML(html)

#     if (json_ld = extract_json_ld(doc)).present?
#       ::RecipeSource::JsonLdStrategy.new(json_ld)
#     elsif doc.at_css('[itemprop]')
#       ::RecipeSource::MicrodataStrategy.new(doc)
#     else
#       ::RecipeSource::FallbackStrategy.new(doc)
#     end
#   end

#   def extract_json_ld(doc)
#     doc.css('script[type="application/ld+json"]').flat_map { |s|
#       JSON.parse(s.text)
#     } rescue []
#     .find { |obj| obj["@type"]&.casecmp("Recipe") == 0 }
#   end
# end






# class RecipeSource::Sourcer
#   require 'nokogiri'
#   require 'open-uri'

#   def initialize(recipe_source)
#     @recipe_source = recipe_source
#   end

#   def update_recipe_source_with_original_info
#     @recipe_source.update!(
#       original_title: get_original_title,
#       image_url: get_original_image,
#       ingredients: get_ingredients
#     )
#   end

#   def test
#     puts get_ingredients
#   end

#   private

#   def get_original_title
#     url = @recipe_source.url
#     URI.open(url,
#       "User-Agent" => "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
#       ) do |f|
#       doc = Nokogiri::HTML(f)
#       original_title = doc.at('h1').text
#     end
#   end

#   def get_ingredients
#     url = @recipe_source.url
#     URI.open(url, "User-Agent" => "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148") do |f|
#       doc = Nokogiri::HTML(f)
  
#       # Find all script tags with type 'application/ld+json'
#       script_tags = doc.css('script[type="application/ld+json"]')
  
#       # Iterate through each script tag and check for the correct Recipe data inside @graph
#       script_tags.each do |script_tag|
#         js = script_tag.text
#         begin
#           parsed = JSON.parse(js)
  
#           # If there's a @graph, check the elements inside it
#           if parsed["@graph"]
#             recipe_data = parsed["@graph"].find { |entry| entry["@type"] == "Recipe" }
  
#             if recipe_data
#               ingredients = recipe_data["recipeIngredient"]
#               puts "Ingredients: #{ingredients}"
#               return ingredients
#             end
#           elsif parsed["@type"] == "Recipe"
#             # If the Recipe is not in @graph but directly in the script
#             ingredients = parsed["recipeIngredient"]
#             puts "Ingredients: #{ingredients}"
#             return ingredients
#           end
#         rescue JSON::ParserError => e
#           puts "Error parsing JSON in script tag: #{e.message}"
#         end
#       end
  
#       # If no recipe is found in any of the script tags
#       puts "No recipe found in JSON-LD data."
#       return nil
#     end
#   end
  
  

#   def get_original_image
#     url = @recipe_source.url
#     URI.open(url,
#       "User-Agent" => "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
#       ) do |f|
#       doc = Nokogiri::HTML(f)
#       if doc.css("meta[property='og:image']").present?                                                                                                                                                                                                                                                                    
#         img_url = doc.css("meta[property='og:image']").first.attributes["content"].value
#       elsif doc.at('script[type="application/ld+json"]').present?
#         js = doc.at('script[type="application/ld+json"]').text
#         parsed = JSON[js]
#         img_url = parsed["image"]
#         #img_url = parsed["image"]["url"] if parsed["image"]["url"].present?
#       else
#         img_tag = doc.css("img").lazy.filter_map { |tag| tag.attributes["src"] if tag.attributes["src"].present? }.first 
#         if img_tag.value.start_with?("http", "www") 
#           img_url = img_tag.value
#         else
#           path = img_tag.value
#           base = f.base_uri.host
#           scheme = f.base_uri.scheme
#           origin = scheme + "://" + base
#           img_url = URI.join(origin, path).to_s
#         end                                                                                                                                                                                                                                    
#       end
#       return img_url
#     end
#   end

# end