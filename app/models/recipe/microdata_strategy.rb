# app/models/recipe_source/microdata_strategy.rb
require 'cgi'

class Recipe::MicrodataStrategy
  def initialize(doc)
    @doc = doc
  end

    def extract_recipe_title(node)
      # Try headline first (most specific)
      headline = node.at_css('[itemprop="headline"]')
      return headline.text.strip if headline

      # Look for recipe name that's not nested in publisher or author scope
      name_elements = node.css('[itemprop="name"]')
      name_elements.each do |elem|
        # Skip if this name is within publisher or author itemscope
        parent_scope = elem.ancestors.find { |a| a['itemscope'] }
        if parent_scope
          itemtype = parent_scope['itemtype']
          next if itemtype&.include?('Organization') || itemtype&.include?('Person')
        end
        return elem.text.strip
      end

      # Fallback: just get any name element
      node.at_css('[itemprop="name"]')&.text&.strip
    end


  # public API: same keys as JsonLdStrategy#extract_all
  def extract_all
    node           = find_recipe_scope
    {
      original_title:    extract_recipe_title(node),
      image_url:         extract_image(node),
      raw_ingredients:   node.css('[itemprop="recipeIngredient"]').map { _1.text.strip },
      directions_struct: extract_directions(node),
      yield_count:       parse_yield(node.at_css('[itemprop="recipeYield"]')&.text)&.fetch(:count),
      yield_unit:        parse_yield(node.at_css('[itemprop="recipeYield"]')&.text)&.fetch(:unit),
      locale:            node['lang'] || I18n.locale.to_s
    }
  end

  private

  # If there’s a top-level itemscope Recipe, use that; otherwise whole doc
  def find_recipe_scope
    @doc.at_css('[itemscope][itemtype*="Recipe"]') || @doc
  end

  # <img itemprop="image"> or <meta itemprop="image" content="…">
  def extract_image(node)
    img = node.at_css('[itemprop="image"]')
    return unless img
    img.name == 'meta' ? img['content'] : (img['src'] || img.text.strip)
  end

# Build the same “directions_struct” as JsonLdStrategy
def extract_directions(node)
  instr_nodes = node.css('[itemprop="recipeInstructions"]')
  return [] if instr_nodes.empty?

  # -------------------------------------------------------------
  # 1) proper HowToSection / HowToStep micro-data
  # -------------------------------------------------------------
  sections = instr_nodes.select { |n| n['itemtype'].to_s.include?('HowToSection') }
  unless sections.empty?
    return sections.map.with_index(1) do |sec, idx|
      steps = sec.css('[itemprop="itemListElement"] [itemprop="text"]')
                 .map   { |e| e.text.strip }
                 .reject(&:blank?)
      { name: sec.at_css('[itemprop="name"]')&.text&.strip,
        steps: steps,
        position: idx }
    end
  end

  # -------------------------------------------------------------
  # 2) pattern: <p><strong>Section</strong><br>text…
  # -------------------------------------------------------------
  container = instr_nodes.first   # simplyrecipes puts everything in one <div>
  if container
    out      = []
    current  = { name: nil, steps: [], position: 1 }

    container.children.each do |child|
      next unless child.element?
      txt = child.text.strip
      next if txt.empty?

      if (hdr = child.at_css('strong')) && hdr.text.strip.present?
        # flush previous section (if it contains steps)
        if current[:steps].any?
          out << current
          current = { name: nil, steps: [], position: out.size + 1 }
        end

        current[:name] = hdr.text.strip

        # anything after the <strong> header in the same <p> is step #1
        rest = txt.sub(hdr.text, '').strip
        current[:steps] << rest unless rest.empty?
      else
        current[:steps] << txt
      end
    end

    out << current if current[:steps].any?
    return out
  end

  # -------------------------------------------------------------
  # 3) flat list – previous behaviour
  # -------------------------------------------------------------
  steps = instr_nodes.flat_map do |n|
    if n['itemtype'].to_s.include?('HowToStep')
      n.at_css('[itemprop="text"]')&.text&.strip
    else
      n.text.strip
    end
  end.compact
  [{ name: nil, steps: steps, position: 1 }]
end


  # Stolen from your JsonLdStrategy parse_yield
  def parse_yield(text)
    case text
    when nil then { count: nil, unit: nil }
    when Integer, Float then { count: text.to_f, unit: nil }
    when String
      if (m = text.match(/(?<num>\d+(\.\d+)?)/))
        cnt  = m[:num].to_f
        unit = text.sub(m[0], '').strip.presence
        { count: cnt, unit: unit }
      else
        { count: nil, unit: text.strip }
      end
    end
  end
end


