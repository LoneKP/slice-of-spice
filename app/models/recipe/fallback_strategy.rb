class Recipe::FallbackStrategy
  def initialize(doc)
    @doc = doc
  end

  def extract_all
    {
      original_title: @doc.at_css('h1')&.text,
      image_url:      @doc.at_css('.recipe-image img')&.[]('src'),
      ingredients:    @doc.css('.ingredients li').map(&:text).join("\n"),
      directions:     @doc.css('.instructions p').map(&:text).join("\n"),
      yield:          @doc.at_css('.yield')&.text
    }
  end
end

