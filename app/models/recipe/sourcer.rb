require "open-uri"

class Recipe::Sourcer
  UA_STRING = "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
  MAX_FILE_SIZE = 10.megabytes
  TIMEOUT_SECONDS = 30

  attr_reader :doc

  def initialize(recipe)
    @recipe = recipe
    @doc = nil
  end

  def update_recipe_with_original_info
    fetch_and_parse_document
    
    data = extract_recipe_data
    raise "No valid recipe data found!" unless data

    update_recipe_data(data)
  end

  private

  def fetch_and_parse_document
    html = fetch_html(@recipe.url)
    @doc = Nokogiri::HTML(html)
  rescue OpenURI::HTTPError => e
    raise "Failed to fetch recipe: HTTP #{e.message}"
  rescue SocketError, Timeout::Error => e
    raise "Network error while fetching recipe: #{e.message}"
  rescue Nokogiri::XML::SyntaxError => e
    raise "Invalid HTML document: #{e.message}"
  end

  def fetch_html(url)
    URI.open(url, 
      "User-Agent" => UA_STRING,
      content_length_proc: ->(size) { 
        raise "File too large: #{size} bytes" if size && size > MAX_FILE_SIZE 
      },
      read_timeout: TIMEOUT_SECONDS,
      open_timeout: TIMEOUT_SECONDS
    ) { |f| f.read(MAX_FILE_SIZE) }
  end

  def extract_recipe_data
    strategies = [
      -> { 
        recipe_ld = extract_json_ld(@doc)
        recipe_ld ? ::Recipe::JsonLdStrategy.new(recipe_ld) : nil 
      },
      -> { @doc.at_css('[itemprop]') ? ::Recipe::MicrodataStrategy.new(@doc) : nil },
      -> { ::Recipe::FallbackStrategy.new(@doc) }
    ]

    strategies.each do |strategy_builder|
      strategy = strategy_builder.call
      next unless strategy
      
      data = extract_or_nil(strategy)
      return data if data
    end

    nil
  end

  def extract_or_nil(strategy)
    data = strategy.extract_all
    return nil unless data.is_a?(Hash)

    required_fields_present?(data) ? data : nil
  rescue StandardError => e
    Rails.logger.warn "Strategy extraction failed: #{e.message}"
    nil
  end

  def required_fields_present?(data)
    has_title = data[:original_title].present?
    has_ingredients = data[:raw_ingredients].present?
    has_instructions = data[:directions_struct].present? &&
                      data[:directions_struct].any? { |s| s[:steps].present? }

    has_title && has_ingredients && has_instructions
  end

  def extract_json_ld(doc)
    doc.css('script[type="application/ld+json"]').each do |tag|
      recipe = parse_json_ld_tag(tag)
      return recipe if recipe
    end
    nil
  end

  def parse_json_ld_tag(tag)
    return nil if tag.text.blank?
    
    data = JSON.parse(tag.text.strip)
    candidates = extract_candidates(data)
    
    candidates.find { |obj| recipe_object?(obj) }
  rescue JSON::ParserError => e
    Rails.logger.debug "JSON-LD parse error: #{e.message}"
    nil
  end

  def extract_candidates(data)
    case data
    when Array then data.flatten.compact
    when Hash  
      if data["@graph"].is_a?(Array)
        data["@graph"].flatten.compact
      else
        [data]
      end
    else
      []
    end
  end

  def recipe_object?(obj)
    return false unless obj.is_a?(Hash)
    
    types = Array(obj["@type"])
    types.any? { |type| type.to_s.casecmp("Recipe").zero? }
  end

  def update_recipe_data(data)
    ActiveRecord::Base.transaction do
      update_master_fields(data)
      rebuild_ingredients(data)
      rebuild_directions(data)
    end
  end

  def update_master_fields(data)
    @recipe.update!(
      original_title: data[:original_title],
      image_url:      data[:image_url],
      yield:          data[:yield_count],
      yield_unit:     data[:yield_unit]
    )
  end

  def rebuild_ingredients(data)
    @recipe.recipe_ingredients.delete_all
    data[:raw_ingredients].each_with_index do |line, idx|
      parsed = IngredientParser.parse(line, data[:locale])
      ing = Ingredient.find_or_create_by!(name: parsed[:normalized_name])
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
  end

  def rebuild_directions(data)
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