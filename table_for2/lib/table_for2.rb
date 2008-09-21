require 'builder'

module TableFor2

  def table_for( collection, options = {}, &block )
    raise ArgumentError, "block required" unless block_given?

    table = TableBuilder.new( self, options )
    yield table

    table.build_table_for collection
  end

  class TableBuilder

    attr_accessor :columns
    attr_accessor :options, :title
    attr_accessor :builder

    def initialize( template, options = {} )
      @template, @options = template, options
      @columns = []
      @builder = Builder::XmlMarkup.new(:indent => 2)

      @title = options.delete(:title)
    end

    def column( method = nil, options = {}, &block )
      columns << if method 
                   simple_column(method, options, &block)
                 else
                   complex_column( options, &block )
                 end
    end

    def default_actions_column( options = {}, &block )
      column :default_actions, options, &block
    end

    def build_table_for(collection)
      @builder.div(:class => 'api_table'){ |d|
        d.table(options) { |t|

          t.caption(title) if title

          t.thead { header_row }

          t.tbody { 
            if collection.empty?
              emtpy_row
            else
              collection.each { |item| body_row(item) }
            end
          }
        }
      }
    end

    def header_row
      @builder.tr {
        columns.each do |col|
          col.header_cell
        end
      }
    end

    def body_row( item )
      @builder.tr(:id => idize(item), :class => @template.cycle("odd", "even")){ 
        columns.each do |col|
          col.body_cell( item )
        end
      }
    end

    def emtpy_row
      @builder.tr { |tr|
        tr.td( "-- No Data --", {:colspan => columns.size, :class => 'empty'} )
      }
    end

    def default_actions_links( options = {} )
      icons = options[:only] || [:show, :edit, :delete]
      icons.delete(options[:except])

      lambda { |item|
        "\n  " + 
        (icons.include?(:show) ? @template.link_to( icon(:show), :action => 'show', :id => item.id ) + "\n  " : "" ) +
        (icons.include?(:edit) ? @template.link_to( icon(:edit), :action => 'edit', :id => item.id ) + "\n  " : "" ) +
        (icons.include?(:delete) ? @template.link_to( icon(:delete), :action  => 'destroy', :id => item.id ) + "\n" : "")
      }
    end

    protected

    def simple_column(method, options, &block)
      col = TableColumn.new( @template, @builder, options.reverse_merge(:title => method.to_s.titleize) )

      if block_given?
        col.content = lambda { |item| block.call( item.send(method) ) }
      else
        if method == :default_actions 
          col.title = "Actions"
          col.content = default_actions_links( options )
        else
          col.content = lambda { |item| item.send(method) }
        end
      end    
      col
    end

    def complex_column( options, &block )
      TableColumn.new( @template, @builder, options, &block )
    end

    def idize( object, method = nil)
      [object.class.to_s.underscore, method, object.id].compact.join('_')
    end

    def icon(name, options = {})
      @template.image_tag("icons/#{name}.png", :title => name.to_s.titleize)
    end
  end

  class TableColumn
    attr_accessor :cell_attributes, :title, :sortable

    def initialize( template, builder, options = {}, &block )
      @template, @builder = template, builder
      @cell_attributes = {}

      options.symbolize_keys!
      # parse options param into column and cell options
      @title = options.delete(:title) 
      @sortable = options.delete(:sortable) || false

      options.each do |key, value|
        @cell_attributes[key] = (key == :class ? CSSClass.new(value) : value)
      end
      @cell_attributes[:class] ||= CSSClass.new

      yield self if block_given?
      @content ||= lambda { |item| "&nbsp;" }
      @cell_attributes[:class] << css_classize(title) if title
    end

    def header_cell
      # if there's a title, we want builder to html-escape it
      if @title
        @builder.th( @title, :class => @cell_attributes[:class].to_s )
      else
        # but if there's no title, do it in a block, so builder doesnt escape the '&'
        @builder.th( :class => @cell_attributes[:class].to_s ){ |th| th << "&nbsp;" }
      end
    end

    def body_cell( item )
      content = @content.call( item )

      # guess the content type, and format the content/style the cell accordingly
      case content
      when Numeric
        @cell_attributes[:class] << 'number'

      when Date, Time, DateTime
        @cell_attributes[:class] << 'datetime'
        content = @template.respond_to?(:format_datetime) ? @template.format_datetime( content ) : content.to_s(:short)

      end

      @builder.td( @cell_attributes.merge(:class => @cell_attributes[:class].to_s) ) { |td|
        td << (" " * 10) + content.to_s + "\n"
      }
    end

    def content( &block )
      @content = block if block_given?
      @content
    end

    def content= x
      @content = x
    end

    protected

    def css_classize(text)
      text.downcase.gsub(' ', '-')
    end

    class CSSClass
      def initialize(*args)
        if args.size == 1
          @list = args.split(' ')
        else
          @list = args
        end
      end

      def to_s
        @list.compact.uniq.join(' ')
      end

      def << elem
        @list << elem
      end
    end
  end
end

