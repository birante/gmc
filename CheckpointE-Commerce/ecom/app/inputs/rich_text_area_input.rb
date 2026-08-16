class RichTextAreaInput
  include Formtastic::Inputs::Base

  def input_html_options
    { rows: 12 }.merge(super)
  end

  def to_html
    input_wrapping do
      label_html << builder.rich_text_area(method, input_html_options)
    end
  end
end
