# frozen_string_literal: true
require "cgi"

class Recipe::FallbackStrategy
  #------------------------------------------
  # API identical to JsonLdStrategy#extract_all
  #------------------------------------------
  def initialize(doc)
    @doc = doc
  end

  def extract_all
    {
      original_title:    extract_title,
      image_url:         extract_image,
      raw_ingredients:   extract_ingredients,
      directions_struct: extract_directions,
      yield_count:       nil,
      yield_unit:        nil,
      locale:            @doc.at("html")&.[]("lang") || I18n.locale.to_s
    }
  end

  #------------------------------------------
  private
  #------------------------------------------

  # --- Title ----------------------------------------------------
  def extract_title
    @doc.at("h1")&.text&.strip ||
      @doc.at("title")&.text&.strip
  end

  # --- Image ----------------------------------------------------
  def extract_image
    og = @doc.at('meta[property="og:image"]')&.[]("content")
    return og if og&.start_with?("http")

    first = @doc.css("img[src]").find { |img| img["src"] =~ /^https?:\/\// }
    first&.[]("src")
  end

  # --- Ingredients ---------------------------------------------
  # 1) grab any <ul>/<ol> whose preceding heading contains “Ingred”
  # 2) fallback: every <li> containing a digit OR a vulgar fraction
  def extract_ingredients
    ul = @doc.css("h2,h3,h4").find { |h| h.text =~ /ingred/i }&.next_element
    if ul&.name =~ /ul|ol/i && ul.css("li").any?
      ul.css("li").map { |li| clean(li.text) }
    else
      @doc.css("li").map(&:text)
          .select { |t| t =~ /\d|¼|½|¾|⅓|⅔/ }
          .map { |t| clean(t) }
    end
  end

  # --- Directions ----------------------------------------------
  # 1) look for a heading with “Instr”, “Direc”, “Method”
  # 2) collect following <p> and <li> until the next heading
  def extract_directions
    hdr = @doc.css("h2,h3,h4").find { |h| h.text =~ /(instru|direc|method)/i }
    nodes = hdr ? gather_until_next_heading(hdr.next_element) : @doc.css("p,li")

    steps = nodes.map { |n| clean(n.text) }.reject(&:blank?)
    [{ name: hdr&.text&.strip, steps: steps, position: 1 }]
  end

  # --- helpers --------------------------------------------------
  def clean(str)
    CGI.unescapeHTML(str).gsub(/\u00A0/, " ").squeeze(" ").strip
  end

  def gather_until_next_heading(start_node)
    out = []
    node = start_node
    while node && !node.name.match?(/^h[1-6]$/i)
      out << node if %w[p li].include?(node.name)
      node = node.next_element
    end
    out
  end
end
