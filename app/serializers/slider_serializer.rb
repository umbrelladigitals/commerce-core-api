class SliderSerializer
  def initialize(slider)
    @slider = slider
  end

  def as_json
    {
      type: 'slider',
      id: @slider.id.to_s,
      attributes: {
        title: @slider.title,
        subtitle: @slider.subtitle,
        button_text: @slider.button_text,
        button_link: @slider.button_link,
        image_url: @slider.image_url,
        display_order: @slider.display_order,
        active: @slider.active,
        created_at: @slider.created_at,
        updated_at: @slider.updated_at
      }
    }
  end

  def self.collection(sliders)
    {
      data: sliders.map { |slider| new(slider).as_json }
    }
  end
end
