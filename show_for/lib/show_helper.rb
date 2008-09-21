module Api
  module ApiShowHelper
    DETAILS_LIST_CSS_CLASS = 'table-display'

    #
    # Options
    #  {+:enable_links+, +:disable_links+}
    #
    #  {+:enable_back_link+, +:disable_back_link+}
    #
    #  {+:enable_edit_link+, +:disable_edit_link+}
    #
    #  {+:title+}
    def api_show( object, options = {}, &proc )
      raise ArgumentError, "Missing Block" unless block_given?

      options = HashWithIndifferentAccess.new(options)
      if options.has_key? :class
        options[:class] += ' ' + DETAILS_LIST_CSS_CLASS
      else
        options[:class] = DETAILS_LIST_CSS_CLASS
      end

      concat( tag(:dl, options, true ), proc.binding )
      api_show_fields( object, *options, &proc )
      concat('</dl>', proc.binding)
      concat(content_tag( :div, nav_links( object, options ), :class => 'nav_links'), proc.binding)
    end

    def api_show_fields( object, *options, &block )
      raise ArgumentError, "Missing Block" unless block_given?
      options = options.is_a?(Hash) ? options : {}

      yield ShowBuilder.new( object, self, options, block )
    end

    def show(object, method_or_data, options = {}, &block)
      title = if options.has_key?(:title)
                options.delete(:title)
              elsif Symbol === method_or_data
                method_or_data.to_s.titleize
              else
                ''
              end

      data = if Symbol === method_or_data
               d = object.send(method_or_data)
               block_given? ? d : h(d.to_s)
             else
               method_or_data
             end

      if block_given?
        data = yield(data)
      end

      data_tags( title, data, options )
    end

    def show_link(object, method, options = {})
      link = if object.send(method).is_a?(Array)
               object.send(method).map do |child|
                 link_to h(child), (options.delete(:url) || path_to_show_for( child ))
               end
             else
               link_to options.delete(:link_name) || h(object.send(method)), ( options.delete(:url) || path_to_show_for( object.send(method) ) )
             end

      data_tags( options.delete(:title) || method.to_s.titleize, link, options )
    end

    def path_to_show_for(object)
      self.send( object.class.to_s.underscore + "_path", object)
    end

    def path_to_edit_for(object)
      self.send( "edit_" + object.class.to_s.underscore + "_path", object)
    end

    def path_to_index_for(object)
      self.send( object.class.to_s.pluralize.underscore + "_path" )
    end

    def nav_links( object, options = {} )
      return "" if disabled?(:links, options)
      links = []
      links << link_to_back( "Back" ) unless disabled?(:back_link, options)
      links << link_to( "Edit", path_to_edit_for(object) ) unless disabled?(:edit_link, options)
      links.join(" | ")
    end

    def link_to_back(name = "Back", *opts)
      link_to name, 'javascript:history:back()', *opts
    end

    protected

    def disabled?(name, options={})
      if options.has_key?(:"disable_#{name}")
        options[:"disable_#{name}"]
      elsif options.has_key?(:"enable_#{name}")
        not options[:"enable_#{name}"]
      else
        false
      end
    end

    def data_tags( title, content, options = {} )
      content_tag( :dt, title, options ) +
        if content.is_a?(Array)
          content = content.clone  # don't mess with the object that was passed in
          content_tag( :dd, content.shift || "&nbsp;", options.merge(:class => 'first') ) +
            content.map { |c| content_tag( :dd, c.blank? ? "&nbsp;" : c, options ) }.join
        else
          content_tag( :dd, content.blank? ? "&nbsp;" : content, options.merge(:class => 'first') )
        end
    end

    class ShowBuilder

      attr_accessor :object_name, :object, :options

      def initialize( object, template, options, proc )
        @object, @template, @options, @proc = object, template, options, proc
      end

      def show(method, options = {}, &block)
        @template.show(@object, method, options, &block)
      end

      def show_link(method, options = {})
        @template.show_link(@object, method, options)
      end
    end

  end
end
