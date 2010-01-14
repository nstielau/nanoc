require 'test/helper'

class Nanoc2::DefaultsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Make sure attributes are cleaned
    page_defaults = Nanoc2::PageDefaults.new({ 'foo' => 'bar' })
    assert_equal({ :foo => 'bar' }, page_defaults.attributes)
  end

end
