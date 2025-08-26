class Label
  attr_reader :id, :name

  def self.from_gmail_label(gmail_label)
    new(id: gmail_label.id, name: gmail_label.name)
  end

  def initialize(id:, name:)
    @id = id
    @name = name
  end

  def custom_label?
    id.downcase.starts_with?("label_")
  end

  def default_label?
    !custom_label?
  end
end
