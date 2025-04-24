# app/models/ingredient_parser.rb
module IngredientParser
  # Map various unit synonyms (EN/DK) to canonical units
  UNIT_MAP = {
    "tsp"        => "tsp",
    "teaspoon"   => "tsp",
    "teaspoons"  => "tsp",
    "tsk"        => "tsp",
    "tbsp"       => "tbsp",
    "tablespoon" => "tbsp",
    "tablespoons"=> "tbsp",
    "spsk"       => "tbsp",
    "cup"        => "cup",
    "dl"         => "dl",
    "l"          => "l",
    "g"          => "g",
    "gram"       => "g",
    "grams"      => "g",
    "kg"         => "kg"
  }.freeze

  IMPERIAL_TO_ML = {
    "tsp"  => 4.92892,
    "tbsp" => 14.7868,
    "cup"  => 240.0
  }.freeze

  METRIC_UNITS = %w[g kg ml l dl].freeze

  def self.parse(line, locale)
    # Regex: quantity (including fractions), optional unit, name, optional notes
    m = line.match(/\A(?<qty>[\d\s\/\.]+)\s*(?<unit>\w+)?\s+(?<name>[^,]+)(?:,\s*(?<notes>.*))?\z/)

    qty_str = m[:qty].strip rescue nil
    quantity = parse_quantity(qty_str)

    raw_unit = m[:unit]&.downcase
    unit     = UNIT_MAP[raw_unit] || raw_unit

    original_name   = m[:name].strip rescue line
    normalized_name = original_name.downcase
    notes           = m[:notes]&.strip

    # Convert to base metric (ml or g)
    base_q, base_u, m_type = if IMPERIAL_TO_ML[unit]
      [quantity * IMPERIAL_TO_ML[unit], "ml", "volume"]
    elsif METRIC_UNITS.include?(unit)
      # normalize kg->g, l->ml, dl->ml
      case unit
      when "kg" then [quantity * 1000, "g", "weight"]
      when "l"  then [quantity * 1000, "ml", "volume"]
      when "dl" then [quantity * 100, "ml", "volume"]
      else [quantity, unit, unit == "g" ? "weight" : "other"]
      end
    else
      [nil, unit, "other"]
    end

    {
      quantity:       quantity,
      unit:           unit,
      original_name:  original_name,
      normalized_name:normalized_name,
      notes:          notes,
      locale:         locale.to_s,
      base_quantity:  base_q,
      base_unit:      base_u,
      measure_type:   m_type
    }
  end

  def self.parse_quantity(str)
    return nil unless str
    # handle "1 1/2"
    if str.include?('/')
      parts = str.split
      if parts.size == 2
        whole = parts[0].to_f
        num, den = parts[1].split('/').map(&:to_f)
        return whole + num/den
      else
        num, den = str.split('/').map(&:to_f)
        return num/den
      end
    else
      str.to_f
    end
  end
end
