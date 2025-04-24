class Recipe::MicrodataStrategy
  def initialize(doc)
    @doc = doc
  end

  def extract_all
    props = {}
    @doc.css('[itemprop]').each do |node|
      name  = node['itemprop']
      value = node.name == 'meta' ? node['content'] : node.text.strip
      props[name] ||= []
      props[name] << value
    end

    {
      original_title: props['name']&.first,
      image_url:      props['image']&.first,
      ingredients:    props['recipeIngredient']&.join("\n"),
      directions:     props['recipeInstructions']&.join("\n"),
      yield:          props['recipeYield']&.first
    }
  end
end

