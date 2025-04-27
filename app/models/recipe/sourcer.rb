require "open-uri"

class Recipe::Sourcer
  UA_STRING = "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

  attr_reader :doc

  def initialize(recipe)
    @recipe = recipe
  end

  def update_recipe_with_original_info
    # choose the best strategy, but fall back if it extracts nothing
    data = begin
    primary = decide_methodology
    extract_or_nil(primary) ||
      extract_or_nil(::Recipe::FallbackStrategy.new(@doc)) ||
      raise("All strategies empty!")
    end

    ActiveRecord::Base.transaction do
      # update master fields
      @recipe.update!(
        original_title: data[:original_title],
        image_url:      data[:image_url],              # no longer storing the blob
        yield:          data[:yield_count],
        yield_unit:     data[:yield_unit]
      )

      # rebuild ingredients (as before) …
      @recipe.recipe_ingredients.delete_all
      data[:raw_ingredients].each_with_index do |line, idx|
        parsed = IngredientParser.parse(line, data[:locale])
        ing    = Ingredient.find_or_create_by!(name: parsed[:normalized_name])
        ing.ingredient_synonyms.find_or_create_by!(locale: parsed[:locale], name: parsed[:original_name])
        @recipe.recipe_ingredients.create!(
          ingredient:    ing,
          quantity:      parsed[:quantity],
          unit:          parsed[:unit],
          base_quantity: parsed[:base_quantity],
          base_unit:     parsed[:base_unit],
          measure_type:  parsed[:measure_type],
          notes:         parsed[:notes],
          position:      idx + 1
        )
      end

      # rebuild directions
      @recipe.direction_sections.destroy_all
      data[:directions_struct].each do |sec|
        section = @recipe.direction_sections.create!(
          name:     sec[:name],
          position: sec[:position]
        )
        sec[:steps].each_with_index do |text, i|
          section.direction_steps.create!(
            text:     text,
            position: i + 1
          )
        end
      end
    end
  end

  private

  def extract_or_nil(strategy)
    data = strategy.extract_all

    no_title        = data[:original_title].blank?
    no_ingredients  = data[:raw_ingredients].blank?
    no_instructions = data[:directions_struct].blank? ||
                      data[:directions_struct].all? { |s| s[:steps].blank? }

    no_title || no_ingredients || no_instructions ? nil : data
  end

  def decide_methodology
    html  = URI.open(@recipe.url, "User-Agent" => UA_STRING, &:read)
    @doc  = Nokogiri::HTML(html)
  
    if    (recipe_ld = extract_json_ld(@doc)).is_a?(Hash)
      ::Recipe::JsonLdStrategy.new(recipe_ld)
    elsif @doc.at_css('[itemprop]')
      ::Recipe::MicrodataStrategy.new(@doc)
    else
      ::Recipe::FallbackStrategy.new(@doc)
    end
  end

  def extract_json_ld(doc)
    doc.css('script[type="application/ld+json"]').each do |tag|
      begin
        data = JSON.parse(tag.text)
  
        # 🌱  build a flat list of candidate hashes
        candidates =
          case data
          when Array then data
          when Hash  then data["@graph"].is_a?(Array) ? data["@graph"] : [data]
          else            []
          end
  
        recipe = candidates.find do |obj|
          next false unless obj.is_a?(Hash)
  
          types = obj["@type"]
          case types
          when Array  then types.any? { |t| t.to_s.casecmp("Recipe").zero? }
          else                types.to_s.casecmp("Recipe").zero?
          end
        end
  
        return recipe if recipe
      rescue JSON::ParserError
        next
      end
    end
    nil
  end
  
  
end