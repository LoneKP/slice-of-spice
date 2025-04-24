class Recipe::JsonLdStrategy
  def initialize(raw)
    @json = normalize_json(raw)
  end

  # Extract structured data from JSON‑LD
  def extract_all
    y = parse_yield(@json["recipeYield"])

    {
      original_title: @json["name"],
      image_url:      Array(@json["image"]).first,
      raw_ingredients: Array(@json["recipeIngredient"]),
      directions:     Array(@json["recipeInstructions"]),
      yield_count:    y[:count],
      yield_unit:     y[:unit],
      locale:         (@json["inLanguage"] || @json["language"] || I18n.locale.to_s).to_s,
    }
  end

  private

  # Find the first Recipe object in raw JSON‑LD or @graph
  def normalize_json(raw)
    array = Array(raw)
    recipe = array.find { |o| o["@type"]&.casecmp("Recipe")==0 }
    return recipe if recipe

    graphs = array.flat_map { |o| o["@graph"] || [] }
    graphs.find { |o| o["@type"]&.casecmp("Recipe")==0 }
  end

  # Parse yield into numeric count and unit (e.g. "4 servings")
  def parse_yield(yield_field)
    case yield_field
    when Integer, Float
      { count: yield_field.to_f, unit: nil }
    when String
      if m = yield_field.match(/(?<num>\d+(?:\.\d+)?)/)
        count = m[:num].to_f
        unit  = yield_field.sub(m[0], '').strip.presence
        { count: count, unit: unit }
      else
        { count: nil, unit: yield_field }
      end
    else
      { count: nil, unit: yield_field.to_s }
    end
  end
end







# class RecipeSource::JsonLdStrategy
#   def initialize(raw)
#     @json = normalize_json(raw)
#   end

#   private

#   def normalize_json(raw)
#     array = Array(raw)
#     # look for a top-level Recipe
#     recipe = array.find { |o| o["@type"]&.casecmp("Recipe")==0 }
#     return recipe if recipe

#     # some sites nest under @graph
#     graphs = array.flat_map { |o| o["@graph"] || [] }
#     graphs.find { |o| o["@type"]&.casecmp("Recipe")==0 }
#   end

#   public

#   def extract_all
#     debugger
#     {
#       original_title: @json["name"],
#       image_url:      Array(@json["image"]).first,
#       ingredients:    Array(@json["recipeIngredient"]).join("\n"),
#       directions:     Array(@json["recipeInstructions"])
#                          .map { |step| step.is_a?(Hash) ? step["text"] : step }
#                          .join("\n"),
#       yield:          @json["recipeYield"]
#     }
#   end
# end
