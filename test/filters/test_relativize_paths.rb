require 'test/helper'

class Nanoc::Filters::RelativizePathsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_run
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Check
    assert_raises(RuntimeError) do
      filter.run("blah blah")
    end
  end

end
