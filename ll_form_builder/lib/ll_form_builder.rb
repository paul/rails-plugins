class LLFormBuilder < ActionView::Helpers::FormBuilder

  ((field_helpers - %w(label check_box radio_button hidden_field)) + %w(datetime_select date_select)).each do |selector|
    src = <<-END_SRC
      def #{selector}(field, options = {})
        label_field( field, options, super )
      end
      END_SRC
    class_eval src, __FILE__, __LINE__
  end

  def select( field, choices, options = {}, html_options = {})
    label_field( field, options, super )
  end

  def check_box(field, options = {}, checked_value = "1", unchecked_value = "0")
    label_field( field, options, super )
  end

  def radio_button(field, tag_value, options = {})
    label_field( field, options, super )
  end

  protected

  def label_field( field, options, field_html )
    note_tag = if note = options.delete(:note)
                 '<BR />' + @template.content_tag(:span, note, :class => 'note')
               else
                 ''
               end

    @template.content_tag(:li, 
                          label(field, (options[:label] || field.to_s.titleize) + note_tag) + field_html, 
                          :id => "#{@object_name}_#{field}_field")
  end

end
