# frozen_string_literal: true
require "cgi"

module IngredientParser
  ##############################################################
  # 0. CONSTANT TABLES
  ##############################################################

  UNIT_MAP = {
    # metric volume
    "ml"=>"ml","milliliter"=>"ml","milliliters"=>"ml",
    "l"=>"l","liter"=>"l","liters"=>"l",
    "dl"=>"dl",

    # kitchen volume
    "tsp"=>"tsp","teaspoon"=>"tsp","teaspoons"=>"tsp","tsk"=>"tsp",
    "tbsp"=>"tbsp","tablespoon"=>"tbsp","tablespoons"=>"tbsp",
    "spsk"=>"tbsp","spiseskefuld"=>"tbsp",
    "cup"=>"cup",

    # weight
    "g"=>"g","gram"=>"g","grams"=>"g",
    "kg"=>"kg","kilo"=>"kg",

    # tokens that are *not* real units
    "fed"=>nil,"stk"=>nil,"styk"=>nil,"stykker"=>nil
  }.freeze

  IMPERIAL_TO_ML = { "tsp"=>4.92892, "tbsp"=>14.7868, "cup"=>240.0 }.freeze

  ##############################################################
  # 1. REGEXP HELPERS
  ##############################################################

  FRACTION_CHARS = "¼½¾⅐⅑⅒⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞"

  QUANTITY_PATTERN = %r{
      (?:\d+(?:[.,]\d+)?\s+\d+\s*/\s*\d+) | # 1 1/2  (allow spaces)
      (?:\d+(?:[.,]\d+)?\s+[#{FRACTION_CHARS}]) | # 1 ½     | 1.0 ½
      (?:\d+(?:[.,]\d+)?[#{FRACTION_CHARS}]) | # 2½
      (?:\d+\s*/\s*\d+)                    | # 3/4   (allow spaces)
      [#{FRACTION_CHARS}]                  | # ½
      (?:\d+(?:[.,]\d+)?)                  | # 2 | 2.5 | 2,5
      &frac\d+;                              # raw &frac12;
  }x.freeze

  UNIT_PATTERN = Regexp.union(
    UNIT_MAP.select { |_, v| v }.keys.sort_by(&:length).reverse
  ).freeze

  ##############################################################
  # 2. MAIN LINE REGEXP
  ##############################################################

  PATTERN = %r{
    \A
      \s*
      (?<quantity>#{QUANTITY_PATTERN})?        # amount
      (?:\s*(?<unit>#{UNIT_PATTERN}))?         # recognised unit
      \s+
      (?<name>[^()]+?)                         # ingredient name
      (?:\s*\((?<notes>[^)]+)\))?              # optional ( … )
      \s*
    \z
  }xi.freeze

  ##############################################################
  # 3. PUBLIC ENTRY POINT
  ##############################################################

  def self.parse(line, locale)

    line = normalise_html(line.to_s)

    m = PATTERN.match(line)
    return blank_result(line, locale) unless m

    # -- 1. primary quantity & unit --------------------------------
    quantity = m[:quantity] ? numeric(m[:quantity]) : nil

    raw_unit = m[:unit].to_s.gsub(/\s+/, "").downcase
    unit     = UNIT_MAP.key?(raw_unit) ? UNIT_MAP[raw_unit] : raw_unit.presence

    # -- 2. remainder may hide another quantity/unit ---------------
    remainder = m[:name].strip

    if (md = remainder.match(/\A\s*(#{QUANTITY_PATTERN.source})/xi))
      quantity = (quantity || 0) + numeric(md[1])
      remainder = remainder[md[0].length..].lstrip
    end

    if unit.nil? && (md = remainder.match(/\A(#{UNIT_PATTERN.source})/xi))
      token = md[1].gsub(/\s+/, "")
      unit  = UNIT_MAP[token.downcase] || token
      remainder = remainder[md[0].length..].lstrip
    end

    # -- 3. “l øg” / “g ær” guard ----------------------------------
    if (unit == "l" && remainder =~ /\Aøg\b/i) || (unit == "g" && remainder =~ /\Aær\b/i)
      remainder = "#{unit}#{remainder}"
      unit = nil
    end

    original_name   = remainder
    normalized_name = original_name.downcase
    notes           = m[:notes]&.strip

    # -- 4. convert to canonical base unit -------------------------
    base_qty, base_unit, measure_type =
      if quantity && unit
        convert_to_base(quantity, unit)
      else
        [nil, nil, nil]
      end

    {
      original_name:   original_name,
      normalized_name: normalized_name,
      quantity:        quantity,
      unit:            unit,
      base_quantity:   base_qty,
      base_unit:       base_unit,
      measure_type:    measure_type,
      notes:           notes,
      position:        nil,
      locale:          locale
    }
  end

  ##############################################################
  # 4. HELPERS
  ##############################################################

  # -- 4a. whitespace & entity clean-up -------------------------
  NBSP_ALL = /\u00A0|\u202F|\u2009|\u200A|\u2006|\u2003|\u2002|\u2004|\u2005/u.freeze

  def self.normalise_html(str)
    str = str.gsub(/&\s*frac\s*(\d+)\s*;?/i) { "&frac#{$1};" }
    str = CGI.unescapeHTML(str)
    str.gsub!(/&frac(12|14|34);/i) { { "12"=>"½", "14"=>"¼", "34"=>"¾" }[$1] }
    str.tr!("\u2044", "/") 
    str.gsub!(/\p{Z}/, " ")
    str.squeeze!(" ")
    str.strip
  end
  private_class_method :normalise_html

# -- 4b. quantity parser -------------------------------------
FRACTIONS = {
  "¼"=>0.25, "½"=>0.5, "¾"=>0.75,
  "⅓"=>1.0/3, "⅔"=>2.0/3,
  "⅕"=>0.2, "⅖"=>0.4, "⅗"=>0.6, "⅘"=>0.8,
  "⅙"=>1.0/6, "⅚"=>5.0/6,
  "⅛"=>0.125,"⅜"=>0.375,"⅝"=>0.625,"⅞"=>0.875
}.freeze

def self.numeric(tok)
  # 1) normalise
  t = tok.strip.tr("\u00A0,", " .")           # kill NBSP + replace comma
  t.tr!("\u2044", "/")                       # U+2044 → '/'
  t.gsub!(/\s*\/\s*/, "/")                   # rm spaces around slash
  t.squeeze!(" ")

  # 2) HTML entity &fracXY;  (X= numerator, Y = denominator)
  if t =~ /\A&frac\s*(\d)(\d);?\z/i
    return $1.to_f / $2.to_f
  end

  # 3) lone Unicode vulgar fraction (½ etc.)
  return FRACTIONS[t].to_f if FRACTIONS.key?(t)

  # 4) mixed number “2 1/2”
  if t =~ /\A(\d+(?:\.\d+)?)\s+(\d+)\/(\d+)\z/
    return $1.to_f + $2.to_f / $3.to_f
  end

  # 5) mixed number with Unicode fraction “2 ½”
  if t =~ /\A(\d+(?:\.\d+)?)\s+([#{FRACTION_CHARS}])\z/
    return $1.to_f + FRACTIONS[$2].to_f
  end

  # 6) glued Unicode fraction “2½”
  if t =~ /\A(\d+(?:\.\d+)?)([#{FRACTION_CHARS}])\z/
    return $1.to_f + FRACTIONS[$2].to_f
  end

  # 7) pure ASCII fraction “1/2”
  if t =~ /\A(\d+)\/(\d+)\z/
    return $1.to_f / $2.to_f
  end

  # 8) plain int / decimal
  t.to_f
end
private_class_method :numeric

  # -- 4c. base-unit conversion --------------------------------
  def self.convert_to_base(qty, unit)
    case unit
    when "kg" then [qty * 1000, "g",  :weight]
    when "g"  then [qty,          "g",  :weight]
    when "l"  then [qty * 1000, "ml", :volume]
    when "dl" then [qty * 100,  "ml", :volume]
    when "ml" then [qty,          "ml", :volume]
    when "tsp","tbsp","cup"
      [qty * IMPERIAL_TO_ML[unit], "ml", :volume]
    else
      [nil, nil, nil]
    end
  end
  private_class_method :convert_to_base

  # -- 4d. blank fallback --------------------------------------
  def self.blank_result(line, locale)
    {
      original_name:   line,
      normalized_name: line.downcase,
      quantity:        nil,
      unit:            nil,
      base_quantity:   nil,
      base_unit:       nil,
      measure_type:    nil,
      notes:           nil,
      position:        nil,
      locale:          locale
    }
  end
  private_class_method :blank_result
end
