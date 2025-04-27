require 'cgi'

class Recipe::JsonLdStrategy
  def initialize(raw)
    if raw.is_a?(Hash) && recipe_type?(raw["@type"])
      @json = raw
    else
      @json = normalize_json(raw)
    end
    raise ArgumentError, "no Recipe object in JSON-LD" unless @json
  end

  def extract_image
    img = @json["image"]

    case img
    when String
      img                                                  # simple string
    when Array
      first = img.first
      first.is_a?(String) ? first : first["url"]           # array of strings or objects
    when Hash
      img["url"]                                           # ImageObject
    else
      nil
    end
  end

  def extract_all
    raw = Array(@json["recipeInstructions"])

    # Separate out real HowToSection objects vs lone HowToStep/text
    sections = []
    steps_only = []

    raw.each do |instr|
      if instr.is_a?(Hash) && instr["@type"]&.casecmp("HowToSection") == 0
        steps = Array(instr["itemListElement"]).map { |s| s.is_a?(Hash) ? s["text"] : s.to_s }
        sections << { name: instr["name"], steps: steps, position: sections.size + 1 }
      elsif instr.is_a?(Hash) && instr["@type"]&.casecmp("HowToStep") == 0
        steps_only << instr["text"]
      else
        steps_only << instr.to_s
      end
    end

    # If we saw **no** actual sections, collapse all steps into one section:
    if sections.empty?
      directions_struct = [
        { name: nil, steps: steps_only, position: 1 }
      ]
    else
      # Otherwise, append any stray steps as a final unnamed section
      if steps_only.any?
        sections << { name: nil, steps: steps_only, position: sections.size + 1 }
      end
      directions_struct = sections
    end

    {
      original_title:    CGI.unescapeHTML(@json["name"].to_s),
      image_url:         extract_image,
      raw_ingredients: Array(@json["recipeIngredient"]).map { |i| CGI.unescapeHTML(i.to_s) },
      directions_struct: directions_struct,
      yield_count:       parse_yield(@json["recipeYield"])[:count],
      yield_unit:        parse_yield(@json["recipeYield"])[:unit],
      locale:            (@json["inLanguage"] || @json["language"] || I18n.locale).to_s
    }
  end


  private

  # Find the first Recipe object in raw JSON‑LD or @graph
  def normalize_json(raw)
    candidates =
      Array(raw).flat_map { |e| e.is_a?(Hash) && e["@graph"].is_a?(Array) ? e["@graph"] : e }
  
    candidates.find do |obj|
      next false unless obj.is_a?(Hash)
  
      types = obj["@type"]
      case types
      when Array  then types.any? { |t| t.is_a?(String) && t.casecmp("Recipe").zero? }
      when String then types.casecmp("Recipe").zero?
      else              false
      end
    end
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

  def recipe_type?(types)
    case types
    when String
      types.casecmp("Recipe").zero?
    when Array
      types.any? { |t| t.is_a?(String) && t.casecmp("Recipe").zero? }
    else
      false
    end
  end
end