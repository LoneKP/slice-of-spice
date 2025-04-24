module Recipe::Sourced
  def sourcer
    @sourcer ||= Recipe::Sourcer.new(self)
  end
end
