require 'helper'

class Nanoc::PageRepTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("some content", { 'foo' => 'bar' }, '/foo/')
    page.site = site

    # Get rep
    page.build_reps
    page_rep = page.reps.first

    # Assert content set
    assert_equal('some content', page_rep.instance_eval { @content[:pre] })
    assert_equal(nil,            page_rep.instance_eval { @content[:post] })

    # Assert flags reset
    assert(page_rep.instance_eval { !@compiled })
    assert(page_rep.instance_eval { !@modified })
    assert(page_rep.instance_eval { !@created })
    assert(page_rep.instance_eval { !@filtered_pre })
    assert(page_rep.instance_eval { !@filtered_post })
  end

  def test_to_proxy
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    page.site = site

    # Get rep
    page.build_reps
    page_rep = page.reps.first

    # Create proxy
    page_rep_proxy = page_rep.to_proxy

    # Check values
    assert_equal('bar', page_rep_proxy.foo)
  end

  def test_created_modified_compiled
    # Create data
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')
    layout = Nanoc::Layout.new('[<%= @page.content %>]', {}, '/default/')
    page = Nanoc::Page.new('content', { 'foo' => 'bar' }, '/foo/')

    # Create site and other requisites
    stack = []
    compiler = mock
    compiler.stubs(:stack).returns(stack)
    router = mock
    router.expects(:disk_path_for).returns('tmp/out/foo/index.html')
    site = mock
    site.expects(:compiler).at_least_once.returns(compiler)
    site.expects(:router).returns(router)
    site.expects(:config).at_least_once.returns({ :output_dir => 'tmp/out' })
    site.expects(:page_defaults).at_least_once.returns(page_defaults)
    site.expects(:pages).at_least_once.returns([ page ])
    site.expects(:assets).at_least_once.returns([])
    site.expects(:layouts).at_least_once.returns([ layout ])
    page.site = site

    # Get rep
    page.build_reps
    page_rep = page.reps.first

    # Check
    assert(!page_rep.created?)
    assert(!page_rep.modified?)
    assert(!page_rep.compiled?)

    # Compile page rep
    page_rep.compile(true, false, true)

    # Check
    assert(page_rep.created?)
    assert(page_rep.modified?)
    assert(page_rep.compiled?)

    # Compile page rep
    page_rep.compile(true, false, true)

    # Check
    assert(!page_rep.created?)
    assert(!page_rep.modified?)
    assert(page_rep.compiled?)

    # Edit and compile page rep
    page.instance_eval      { @mtime = Time.now + 5 }
    page_rep.instance_eval  { @content[:pre] = 'new content' }
    page_rep.compile(true, false, true)

    # Check
    assert(!page_rep.created?)
    assert(page_rep.modified?)
    assert(page_rep.compiled?)
  end

  def test_outdated
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create layouts
    layouts = [
      Nanoc::Layout.new('layout 1', {}, '/layout1/'),
      Nanoc::Layout.new('layout 2', {}, '/layout2/')
    ]

    # Create code
    code = Nanoc::Code.new('def stuff ; "moo" ; end')

    # Create site
    site = mock
    site.expects(:page_defaults).at_least_once.returns(page_defaults)
    site.expects(:layouts).at_least_once.returns(layouts)
    site.expects(:code).at_least_once.returns(code)

    # Create page
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]
    page_rep.stubs(:disk_path).returns('tmp/out/foo/index.html')

    # Make everything up to date
    page.instance_eval { @mtime = Time.now - 100 }
    FileUtils.mkdir_p('tmp/out/foo')
    File.open(page_rep.disk_path, 'w') { |io| }
    File.utime(Time.now - 50, Time.now - 50, page_rep.disk_path)
    page_defaults.instance_eval { @mtime = Time.now - 100 }
    layouts.each { |l| l.instance_eval { @mtime = Time.now - 100 } }
    code.instance_eval { @mtime = Time.now - 100 }

    # Assert not outdated
    assert(!page_rep.outdated?)

    # Check with nil mtime
    page.instance_eval { @mtime = nil }
    assert(page_rep.outdated?)
    page.instance_eval { @mtime = Time.now - 100 }
    assert(!page_rep.outdated?)

    # Check with non-existant output file
    FileUtils.remove_entry_secure(page_rep.disk_path)
    assert(page_rep.outdated?)
    FileUtils.mkdir_p('tmp/out/foo')
    File.open(page_rep.disk_path, 'w') { |io| }
    assert(!page_rep.outdated?)

    # Check with older mtime
    page.instance_eval { @mtime = Time.now }
    assert(page_rep.outdated?)
    page.instance_eval { @mtime = Time.now - 100 }
    assert(!page_rep.outdated?)

    # Check with outdated layouts
    layouts[0].instance_eval { @mtime = Time.now }
    assert(page_rep.outdated?)
    layouts[0].instance_eval { @mtime = nil }
    assert(page_rep.outdated?)
    layouts[0].instance_eval { @mtime = Time.now - 100 }
    assert(!page_rep.outdated?)

    # Check with outdated page defaults
    page_defaults.instance_eval { @mtime = Time.now }
    assert(page_rep.outdated?)
    page_defaults.instance_eval { @mtime = nil }
    assert(page_rep.outdated?)
    page_defaults.instance_eval { @mtime = Time.now - 100 }
    assert(!page_rep.outdated?)

    # Check with outdated code
    code.instance_eval { @mtime = Time.now }
    assert(page_rep.outdated?)
    code.instance_eval { @mtime = nil }
    assert(page_rep.outdated?)
    code.instance_eval { @mtime = Time.now - 100 }
    assert(!page_rep.outdated?)
  end

  def test_disk_and_web_path
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create router
    router = mock
    router.expects(:disk_path_for).returns('tmp/out/pages/path/index.html')
    router.expects(:web_path_for).returns('/pages/path/')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)
    site.expects(:router).times(2).returns(router)

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :default }

    # Check
    assert_equal('tmp/out/pages/path/index.html', page_rep.disk_path)
    assert_equal('/pages/path/',                  page_rep.web_path)
  end

  def test_attribute_named_with_custom_rep
    # Should check in
    # 1. page rep
    # 2. page default's page rep
    # 3. hardcoded defaults

    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new({
      :reps => { :custom => {
        :one => 'one in page defaults rep',
        :two => 'two in page defaults rep'
      }}
    })

    # Create site
    site = mock
    site.expects(:page_defaults).at_least_once.returns(page_defaults)

    # Create page and rep
    page = Nanoc::Page.new(
      "content",
      { :reps => { :custom => { :one => 'one in page rep' } } },
      '/path/'
    )
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :custom }

    # Test finding one
    assert_equal('one in page rep', page_rep.attribute_named(:one))

    # Test finding two
    assert_equal('two in page defaults rep', page_rep.attribute_named(:two))

    # Test finding three
    assert_equal('default', page_rep.attribute_named(:layout))
  end

  def test_attribute_named_with_default_rep
    # Should check in
    # 1. page rep
    # 2. page
    # 3. page defaults' page rep
    # 4. page defaults
    # 5. hardcoded defaults

    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new({
      :one    => 'one in page defaults',
      :two    => 'two in page defaults',
      :three  => 'three in page defaults',
      :four   => 'four in page defaults',
      :reps => { :default => {
        :one    => 'one in page defaults rep',
        :two    => 'two in page defaults rep',
        :three  => 'three in page defaults rep'
      }}
    })

    # Create site
    site = mock
    site.expects(:page_defaults).at_least_once.returns(page_defaults)

    # Create page and rep
    page_attrs = {
      :oen  => 'one in page',
      :two  => 'two in page',
      :reps => { :default => { :one => 'one in page rep' } }
    }
    page = Nanoc::Page.new('content', page_attrs, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :default }

    # Test finding one
    assert_equal('one in page rep', page_rep.attribute_named(:one))

    # Test finding two
    assert_equal('two in page', page_rep.attribute_named(:two))

    # Test finding three
    assert_equal('three in page defaults rep', page_rep.attribute_named(:three))

    # Test finding four
    assert_equal('four in page defaults', page_rep.attribute_named(:four))

    # Test finding five
    assert_equal('default', page_rep.attribute_named(:layout))
  end

  def test_content_pre
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Mock compiler
    page_rep.expects(:compile).with(false, false, false)
    page_rep.instance_eval { @content = { :pre => 'pre!', :post => 'post!' } }

    # Check
    assert_equal('pre!', page_rep.content(:pre))
  end

  def test_content_post
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Mock compiler
    page_rep.expects(:compile).with(true, false, false)
    page_rep.instance_eval { @content = { :pre => 'pre!', :post => 'post!' } }

    # Check
    assert_equal('post!', page_rep.content(:post))
  end

  def test_layout_without_layout
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", { :layout => 'none' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Check
    assert_equal(nil, page_rep.layout)
  end

  def test_layout_with_unknown_layout
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:layouts).returns([])
    site.expects(:page_defaults).returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", { :layout => 'dffrvsserg' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Check
    assert_raise(Nanoc::Errors::UnknownLayoutError) { page_rep.layout }
  end

  def test_layout_normal
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create layout
    layout = Nanoc::Layout.new('header <%= @page.content %> footer', {}, '/foo/')

    # Create site
    site = mock
    site.expects(:layouts).returns([ layout ])
    site.expects(:page_defaults).returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", { :layout => 'foo' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Check
    assert_equal(layout, page_rep.layout)
  end

  def test_compile
    # TODO implement

    # - check stack
    # - check recursive call
    # - check notifications
  end

  def test_compile_without_layout
    # TODO implement
  end

  def test_compile_also_layout
    # TODO implement
  end

  def test_compile_even_when_outdated
    # TODO implement
  end

  def test_compile_from_scratch
    # TODO implement
  end

  def test_do_compile_pre
    # TODO implement
  end

  def test_do_compile_post
    # TODO implement
  end

  def test_do_write
    # TODO implement
  end

  def test_do_filter
    # TODO implement
  end

  def test_do_filter_get_filters_for_stage
    # TODO implement
  end

  def test_do_filter_chained
    # TODO implement
  end

  def test_do_filter_with_unknown_filter
    # TODO implement
  end

  def test_do_filter_with_outdated_filters_attribute
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", { :filters => [ 'asdf' ] }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Filter
    assert_raise Nanoc::Errors::NoLongerSupportedError do
      page_rep.instance_eval { do_filter(:pre) }
    end
  end

  def test_do_layout
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:config).returns([])
    site.expects(:assets).returns([])
    site.expects(:pages).returns([])
    site.expects(:layouts).returns([])
    site.expects(:page_defaults).at_least_once.returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", {}, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Create layout
    layout = Nanoc::Layout.new('this is a layout', { :filter => 'erb' }, '/foo/')
    page_rep.expects(:layout).at_least_once.returns(layout)

    # Layout
    assert_nothing_raised { page_rep.instance_eval { do_layout } }
    assert_equal('this is a layout', page_rep.instance_eval { @content[:post] })
  end

  def test_do_layout_without_layout
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).at_least_once.returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", {}, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]
    page_rep.expects(:attribute_named).with(:layout).returns(nil)

    # Layout
    page_rep.instance_eval { @content[:pre] = 'pre content' }
    assert_nothing_raised { page_rep.instance_eval { do_layout } }
    assert_equal('pre content', page_rep.instance_eval { @content[:post] })
  end

  def test_do_layout_with_unknown_filter
    # Create page defaults
    page_defaults = Nanoc::PageDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).at_least_once.returns(page_defaults)

    # Create page
    page = Nanoc::Page.new("content", {}, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Create layout
    layout = Nanoc::Layout.new('this is a layout', { :filter => 'sdfdfvarg' }, '/foo/')
    page_rep.expects(:layout).at_least_once.returns(layout)

    # Layout
    assert_raise(Nanoc::Errors::CannotDetermineFilterError) do
      page_rep.instance_eval { do_layout }
    end
  end

  def test_write_page
    # TODO implement
  end

  def test_write_page_with_skip_output
    # TODO implement
  end

end