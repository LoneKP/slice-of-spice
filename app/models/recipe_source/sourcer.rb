class RecipeSource::Sourcer
  require 'nokogiri'
  require 'open-uri'

  def initialize(recipe_source)
    @recipe_source = recipe_source
  end

  def update_recipe_source_with_original_title
    @recipe_source.update!(
      original_title: get_original_title,
      image_url: get_original_image
    )
  end

  private

  def get_original_title
    url = @recipe_source.url
    URI.open(url,
      "User-Agent" => "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
      ) do |f|
      doc = Nokogiri::HTML(f)
      original_title = doc.at('h1').text
    end
  end

  def get_original_image
    url = @recipe_source.url
    URI.open(url,
      "User-Agent" => "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
      ) do |f|
      doc = Nokogiri::HTML(f)
      if doc.css("meta[property='og:image']").present?                                                                                                                                                                                                                                                                    
        img_url = doc.css("meta[property='og:image']").first.attributes["content"].value
      elsif doc.at('script[type="application/ld+json"]').present?
        js = doc.at('script[type="application/ld+json"]').text
        parsed = JSON[js]
        img_url = parsed["image"]
        #img_url = parsed["image"]["url"] if parsed["image"]["url"].present?
      else
        img_tag = doc.css("img").lazy.filter_map { |tag| tag.attributes["src"] if tag.attributes["src"].present? }.first 
        if img_tag.value.start_with?("http", "www") 
          img_url = img_tag.value
        else
          path = img_tag.value
          base = f.base_uri.host
          scheme = f.base_uri.scheme
          origin = scheme + "://" + base
          img_url = URI.join(origin, path).to_s
        end                                                                                                                                                                                                                                    
      end
      return img_url
    end
  end

end