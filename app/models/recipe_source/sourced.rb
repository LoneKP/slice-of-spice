module RecipeSource::Sourced
  def sourcer
    @sourcer ||= RecipeSource::Sourcer.new(self)
  end
end
