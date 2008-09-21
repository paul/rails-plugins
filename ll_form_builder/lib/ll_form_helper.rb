module LLFormHelper

  def ll_form_for(record_or_name_or_array, *args, &proc)
    raise ArgumentError, "Missing block" unless block_given?

    options = args.extract_options!
    options[:builder] = LLFormBuilder

    case record_or_name_or_array
    when String, Symbol
      object_name = record_or_name_or_array
    when Array
      object = record_or_name_or_array.last
      object_name = ActionController::RecordIdentifier.singular_class_name(object)
      apply_form_for_options!(record_or_name_or_array, options)
      args.unshift object
    else
      object = record_or_name_or_array
      object_name = ActionController::RecordIdentifier.singular_class_name(object)
      apply_form_for_options!([object], options)
      args.unshift object
    end

    concat(form_tag(options.delete(:url) || {}, (options.delete(:html) || {}).merge(:class => 'labeled-list')), proc.binding)
    concat('<ol>', proc.binding)

    fields_for(object_name, *(args << options), &proc)
    concat( api_form_actions(object_name, options), proc.binding )

    concat('</ol>', proc.binding)
    concat('</form>', proc.binding)
  end

  # The default buttons at the bottom of the form
  # Create if new object, Save if existing
  # link back to show
  def api_form_actions(object_name, options = {})
      "  <li><div class=\"form_actions\">\n    " +
        submit_button(object_name, options[:submit_text]) + "\n  " + cancel_link +
        "\n  </div></li>"
  end

  def submit_button(object_name, text = nil)
    submit_tag(text || (controller.action_name == 'new' ? "Create" : "Save"),
               {:id => "#{object_name}_submit"} )

  end

  # Returns the markup for a "Cancel" link
  def cancel_link
    return_uri = controller.params[:_return_to]
    return_uri ||= controller.request.env['HTTP_REFERER']
    return_uri ||= controller.request.request_uri.gsub(%r{/[^/]+/?$}, "")
    return_uri = '/' if return_uri.empty?

      "<input type='hidden' name='_return_to' value='#{return_uri}'></input><a href='#{return_uri}'>Cancel</a>"
  end

end
