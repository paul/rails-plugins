require "#{File.dirname(__FILE__)}/../../../rails/actionpack/test/abstract_unit"
require File.dirname(__FILE__) + '/../lib/api_show_helper'

require File.dirname(__FILE__) + '/../../link_to_back/lib/link_to_back'

class ApiShowHelperTest < Test::Unit::TestCase
  include Api::ApiShowHelper
  include Api::LinkToBack
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper

  def test_show_url
    assert_equal post_path(@post), path_to_show_for(@post)
  end

  def test_show_url_on_child
    assert_equal author_path(@post.author), path_to_show_for(@post.author)
  end

  def test_edit_url
    assert_equal edit_post_path(@post), path_to_edit_for(@post)
  end

  def test_index_url
    assert_equal posts_path, path_to_index_for(@post)
  end

  def test_nav_links
    links = link_to_back("Back") + ' | <a href="Edit Post 1">Edit</a>'
    assert_dom_equal links, nav_links(@post)
  end

  def test_disable_back_link
    links = '<a href="Edit Post 1">Edit</a>'
    assert_dom_equal links, nav_links(@post, :disable_back_link => true)
  end

  def test_disable_edit_link
    links = link_to_back("Back")
    assert_dom_equal links, nav_links(@post, :disable_edit_link => true)
  end

  def test_disable_both_links
    links = ""
    assert_dom_equal links, nav_links(@post, :disable_links => true)
  end

  def test_show
    assert_dom_equal dt_dd( "Title", @post.title ), show(@post, :title)
  end

  def test_show_join
    assert_dom_equal dt_dd( "Author", @post.author.to_s ), show(@post, :author)
  end

  def test_show_with_array
    assert_kind_of Array, @post.comments
    assert_dom_equal dt_dd( "Comments", @post.comments.first ) + dd( @post.comments[1] ), show(@post, :comments)
  end

  def test_show_with_overridden_title
    assert_dom_equal dt_dd( "ASDFASDF", @post.title ), show(@post, :title, :title => "ASDFASDF")
  end

  def test_show_link_join
    assert_dom_equal dt_dd( "Author", '<a href="Show Author 1">Paul</a>' ), show_link(@post, :author)
  end

  def test_show_link_with_array
    assert_dom_equal dt_dd( "Comments", '<a href="Show Comment 1">First Comment</a>' ) + dd('<a href="Show Comment 2">2nd Comment</a>'), show_link(@post, :comments)
  end

  def test_show_link_overridden_url
    assert_dom_equal dt_dd( "Author", '<a href="My URL">Paul</a>' ), show_link(@post, :author, :url => "My URL")
  end

  def test_api_show
    api_show( @post ) do |s|
      concat s.show( :title )
      concat s.show_link( :author )
      concat s.show_link( :comments )
      concat s.show_link( :body, :title => "Post Body", :url => "My Body URL" )
    end

    expected =
      '<dl class="table-display">' +
        '<dt>Title</dt><dd class="first">Test Post</dd>' +
        '<dt>Author</dt><dd class="first"><a href="Show Author 1">Paul</a></dd>' +
        '<dt>Comments</dt><dd class="first"><a href="Show Comment 1">First Comment</a></dd>' +
          '<dd><a href="Show Comment 2">2nd Comment</a></dd>' +
        '<dt>Post Body</dt><dd class="first"><a href="My Body URL">Test Post body text</a></dd>' +
      '</dl>' +
      '<div class="nav_links">' + link_to_back("Back") + ' | <a href="Edit Post 1">Edit</a></div>'

    assert_dom_equal expected, @output
  end

  def test_api_show__explict_id
    api_show(@post, :id=>"test_api_show__explict_id") do |details|
    end

    assert_select 'dl' do |e|
      assert_equal 'test_api_show__explict_id', e.first['id']
    end

  end

  def test_api_show__explict_class
    api_show(@post, :class=>"test_api_show__explict_class") do |details|
    end

    assert_select 'dl' do |e|
      assert_equal 'test_api_show__explict_class table-display', e.first['class']
    end

  end


  # ---- support stuff ----
  def setup
    @post_author = Author.new( 1, "Paul" )

    @comment_1 = Comment.new( 1, "First Comment", "Comment Body")
    @comment_2 = Comment.new( 2, "2nd Comment", "2nd Comment Body")
    @post_comments = [@comment_1, @comment_2]

    @post = Post.new( 1, "Test Post", @post_author, "Test Post body text", @post_comments )

    @output = ""
 end


  protected

  def post_path( post )
    id = post.is_a?(Numeric) ? post : post.id
    "Show Post #{id}"
  end

  def edit_post_path( post )
    id = post.is_a?(Numeric) ? post : post.id
    "Edit Post #{id}"
  end

  def posts_path
    "Index of posts"
  end

  def author_path( author )
    id = author.is_a?(Numeric) ? author : author.id
    "Show Author #{id}"
  end

  def comment_path( comment )
    id = comment.is_a?(Numeric) ? comment : comment.id
    "Show Comment #{id}"
  end

  def dt_dd( dt, dd, *options )
    "<dt>#{dt}</dt><dd class=\"first\">#{dd}</dd>"
  end

  def dd( dd, *options )
    "<dd>#{dd}</dd>"
  end

  def concat(a_string, binding = nil)
    @output << a_string
  end

  def response_from_page_or_rjs
    HTML::Document.new(@output).root
  end

end

class Post
  attr_accessor :id, :title, :author, :body, :comments
  def initialize( id, title, author, body, comments )
    @id, @title, @author, @body, @comments = id, title, author, body, comments
  end

  def to_s
    title
  end
end

class Comment
  attr_accessor :id, :title, :body
  def initialize( id, title, body )
    @id, @title, @body = id, title, body
  end

  def to_s
    title
  end
end

class Author
  attr_accessor :id, :name
  def initialize( id, name )
    @id, @name = id, name
  end

  def to_s
    name
  end
end
