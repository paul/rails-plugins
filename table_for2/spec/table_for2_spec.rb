require 'active_support'
require File.dirname(__FILE__) + '/../../rspec_xpath_matchers/init'
include Spec::Matchers::XPathMatchers

require File.join(File.dirname(__FILE__), "../lib/table_for2")
include TableFor2

describe TableBuilder do
  before(:each) do
    @tb = TableBuilder.new( self, {} )
  end

  it 'should accept the title option' do
    @tb = TableBuilder.new( self, {:title => "FooBar"} )
    @tb.title.should == "FooBar"
  end

  it 'should accept the title in a block' do
    p = lambda { |t| t.title = "FooBar" }
    p.call(@tb)

    @tb.title.should == "FooBar"
  end

  it 'should add a column object to the list of columns when #column is called in a block' do
    p = lambda { |t| t.column :name }
    p.call @tb

    @tb.columns.size.should == 1
  end

  it 'should call simple_column if the column is simple (got a method name)' do
    @tb.should_receive(:simple_column).and_return(:simple)

    p = lambda { |t| t.column :name }
    p.call @tb

    @tb.columns.should == [:simple]
  end

  it 'should call complex_column if the column is complicated (no method given)' do
    @tb.should_receive(:complex_column).and_return(:complex)

    p = lambda { |t| t.column { |col| nil } }
    p.call @tb

    @tb.columns.should == [:complex]
  end
end

describe TableBuilder, 'simple column with method name' do
  before(:each) do
    @tb = TableBuilder.new( self, {} )

    p = lambda { |t| t.column :name }
    p.call @tb

    @column = @tb.columns.first
  end

  it 'should make a new TableColumn object' do
    @column.should be_kind_of(TableColumn)
  end

  it 'should set the title of the column to the titleized method name' do
    @column.title.should == "Name"
  end

  it 'should send the content of the column to a proc' do
    @column.content.should be_kind_of(Proc)
  end

  it 'should have the content be the result of send-ing the method' do
    item = mock(:item)

    item.should_receive(:name).and_return("item name")
    @column.content.call(item).should == "item name"
  end

end

describe TableBuilder, 'simple column with method name and block' do
  before(:each) do
    @tb = TableBuilder.new( self, {} )

    p = lambda do |t| 
      t.column(:name){ |val| val.upcase }
    end

    p.call @tb

    @column = @tb.columns.first
  end

  it 'should make a new TableColumn object' do
    @column.should be_kind_of(TableColumn)
  end

  it 'should set the title of the column to the titleized method name' do
    @column.title.should == "Name"
  end

  it 'should send the content of the column to a proc' do
    @column.content.should be_kind_of(Proc)
  end

  it 'should have the content be the result of eval-ing the block' do
    item = mock(:item)

    item.should_receive(:name).and_return("item name")
    @column.content.call(item).should == "item name".upcase
  end

end

describe TableBuilder, 'complex column containing only a block' do
  before(:each) do 
    @tb = TableBuilder.new(self, {} )

    p = lambda do |t|
      t.column { |col| col.content { |val| "#{val.name}: #{val.id}" } }
    end
    p.call @tb

    @column = @tb.columns.first
  end

  it 'should make a new TableColumn object' do
    @column.should be_kind_of(TableColumn)
  end

  it 'should send the content of the column to a proc' do
    @column.content.should be_kind_of(Proc)
  end

  it 'should have the content be the result of eval-ing the block' do
    item = mock(:item)

    item.should_receive(:name).and_return("item name")
    item.should_receive(:id).and_return("17")
    @column.content.call(item).should == "item name: 17"
  end
end

describe TableBuilder, 'building the table' do

  before(:each) do
    @template = mock(:template)
    @template.stub!(:cycle).and_return('odd')

    @tb = TableBuilder.new(@template, {})

    p = lambda do |t| 
      t.column :name 

      t.column( :class ){ |val| val.upcase }

      t.column { |col| col.title = "Complex"; col.content { |item| "#{item.id}: #{item.name}" } }
    end

    p.call @tb

    @item = mock(:item)
    @item.stub!(:name).and_return('FooBar')
    @item.stub!(:id).and_return(1)
    @item.stub!(:class).and_return('Item')

  end

  it 'should build the header row' do
    @tb.columns.each_with_index do |col, i|
      col.should_receive(:header_cell).once
    end

    @table = @tb.header_row
  end

  it 'should call the header_row function exactly once' do
    @tb.should_receive(:header_row).once

    @table = @tb.build_table_for([@item])
  end

  it 'should build a body row for an item' do
    @tb.columns.each_with_index do |col, i|
      col.should_receive(:body_cell).with(@item).once
    end

    @table = @tb.body_row(@item)
  end

  it 'should call the body_row function once per item' do
    @tb.should_receive(:body_row).twice

    @table = @tb.build_table_for([@item, @item])
  end

  it 'should have the right header columns even if the collection is empty' do
    @tb.columns.each_with_index do |col, i|
      col.should_receive(:header_cell).once
    end

    @table = @tb.build_table_for([])
  end

  it 'should have an single empty row in the body when the collection is empty' do
    @table = @tb.build_table_for([])

    @table.should have_element("td").with_class('empty').and_attribute('colspan').with_value(@tb.columns.size).contained_in_a('tr')
  end

  it 'should have a whole table structure' do
    @table = @tb.build_table_for([@item])

    @table.should have_element('div').with_class('api_table')
    @table.should have_element('table').contained_in_a('div')

    @table.should have_element('thead').contained_in_a('table')
    @table.should have_element('tr').contained_in_a('thead')
    @table.should have_element('th').with_text('Name').contained_in_a('tr')

    @table.should have_element('tbody').contained_in_a('table')
    @table.should have_element('tr').with_id('item_1').contained_in_a('tbody')
    @table.should have_element('td').with_text('FooBar').contained_in_a('tr')
  end

  it 'should not have a caption if a title is not provided' do
    @table = @tb.build_table_for([@item])

    @table.should_not have_element('caption')
  end

  it 'should have a caption if a title option is provided' do
    @tb = TableBuilder.new(@template, :title => "FooBar")
    p = lambda { |t| t.column :name }
    p.call @tb

    @tb.stub!(:header_row).and_return("dont care")
    @tb.stub!(:body_row).and_return("dont care")

    @table = @tb.build_table_for([@item])

    @table.should have_element('caption').with_text('FooBar').contained_in_a('table')
  end
end

describe TableColumn, 'common' do
  def new_table_column(opts = {})
    @tc = TableColumn.new( self, Builder::XmlMarkup.new, opts )
  end

  it 'should should convert options[:title] into the title attribute' do
    @tc = new_table_column(:title => 'FooBar')
    @tc.title.should == 'FooBar'
  end

  it 'should create a CSSClass object on options[:class]' do
    @tc = new_table_column
    @tc.cell_attributes[:class].should be_kind_of(TableColumn::CSSClass)
  end

  it 'should create a CSSClass with the classes given' do
    @tc = new_table_column(:class => 'foo bar')
    @tc.cell_attributes[:class].to_s.should == 'foo bar'
  end

  it 'should set content to &nbsp; block if no content was provided in the block' do
    @tc = new_table_column
    @tc.content.should be_kind_of(Proc)
    @tc.content.call(nil).should == "&nbsp;"
  end

  it 'should add a css class-ized version of the title to the :class' do
    @tc = new_table_column(:title => 'Foo Bar')
    @tc.title.should == 'Foo Bar'
    @tc.cell_attributes[:class].to_s.should == 'foo-bar'
  end

  it 'should add any arbitrary option to the cell_attributes' do
    @tc = new_table_column(:foo => 'bar')
    @tc.cell_attributes[:foo].should == 'bar'
  end
end

describe TableColumn, 'header cell' do
  before(:each) do
    @builder = Builder::XmlMarkup.new
    @tc = TableColumn.new( self, @builder, {:title => 'Foo Bar', :class => 'test-class'} )
  end

  it 'should be a correct th tag' do
    out = @tc.header_cell

    out.should have_element('th').with_class('test-class').and_class('foo-bar').and_text('Foo Bar')
  end
end

describe TableColumn, 'body cell' do
  before(:each) do
    @builder = Builder::XmlMarkup.new

    @item = mock(:item)
    @item.stub!(:name).and_return('baz')
    @item.stub!(:id).and_return(1)
    @item.stub!(:updated_at).and_return(Time.now)

    self.stub!(:format_datetime).and_return('formatted!')
  end

  def new_table_column(opts = {}, &block)
    TableColumn.new(self, @builder, opts, &block)
  end

  it 'should have the class from the title' do
    @tc = new_table_column(:title => 'Foo Bar')
    @tc.body_cell(@item).should have_element('td').with_class('foo-bar')
  end

  it 'should have the correct content' do
    @tc = new_table_column { |col| col.content { |item| item.name } }
    @tc.body_cell(@item).should have_element('td').with_text( @item.name )
  end

  it 'should have class "number" if content is a Numeric' do
    @tc = new_table_column { |col| col.content { |item| item.id } }
    @tc.body_cell(@item).should have_element('td').with_class('number')
  end

  it 'should have class "datetime" and get formatted if content is a Time' do
    @tc = new_table_column { |col| col.content { |item| item.updated_at } }

    self.should_receive(:format_datetime).once.and_return(Time.now.to_s)
    out = @tc.body_cell(@item)
    out.should have_element('td').with_class('datetime')
  end
end


describe TableColumn::CSSClass do
  it 'should accept a list of css classes in initialize' do
    @css = TableColumn::CSSClass.new('a b c')

    @css.to_s.should == 'a b c'
  end

  it 'should accept an array of css classes in initialize' do
    @css = TableColumn::CSSClass.new('a', 'b', 'c')

    @css.to_s.should == 'a b c'
  end

  it 'should allow more classes to be appended' do
    @css = TableColumn::CSSClass.new('a b')
    @css << 'c'

    @css.to_s.should == 'a b c'
  end

end

