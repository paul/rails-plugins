require File.join(File.dirname(__FILE__), 'lib/api_show_helper')

ActionView::Base.send :include, Api::ApiShowHelper
