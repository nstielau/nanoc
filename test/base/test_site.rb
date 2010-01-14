require 'test/helper'

class Nanoc2::SiteTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestDataSource < Nanoc2::DataSource

    identifier :test_data_source

    def code ; Nanoc2::Code.new('') ; end

  end

  class TestOldschoolDataSource < Nanoc2::DataSource

    identifier :test_oldschool_data_source

    def pages
      [
        { :uncompiled_content => 'Hi!',          :path => '/'       },
        { :uncompiled_content => 'Hello there.', :path => '/about/' }
      ]
    end

    def page_defaults
      { :layout => 'quux' }
    end

    def layouts
      [
        {
          :path       => '/quux/',
          :content    => "<html>\n" +
                         "  <head>\n" +
                         "    <title><%= @page.title %></title>\n" +
                         "  </head>\n" +
                         "  <body>\n" +
                         "<%= @page.content %>\n" +
                         "  </body>\n" +
                         "</html>",
          :meta       => { :filter => 'erb' }
        }
      ]
    end

    def templates
      [
        {
          :name     => 'default',
          :content  => 'Hi, I am a new page. Please edit me!',
          :meta     => { :title => 'A New Page' }
        }
      ]
    end

    def code
      "def foo ; 'bar' ; end"
    end

  end

  class TestNewschoolDataSource < Nanoc2::DataSource

    identifier :test_newschool_data_source

    def pages
      [
        Nanoc2::Page.new("Hi!",          {}, '/'),
        Nanoc2::Page.new("Hello there.", {}, '/about/')
      ]
    end

    def page_defaults
      Nanoc2::PageDefaults.new({ :foo => 'bar' })
    end

    def layouts
      [
        Nanoc2::Layout.new(
          'HEADER <%= @page.content %> FOOTER',
          { :filter => 'erb' },
          '/quux/'
        )
      ]
    end

    def templates
      [
        Nanoc2::Template.new('Content Here', { :foo => 'bar' }, 'default')
      ]
    end

    def code
      Nanoc2::Code.new("def something_random ; 'something random, yah' ; end")
    end

  end

  class TestEarlyLoadingCodeDataSource < Nanoc2::DataSource

    identifier :early_loading_code_data_source

    def pages
      [
        Nanoc2::Page.new("Hi!",          {}, '/'),
        Nanoc2::Page.new("Hello there.", {}, '/about/')
      ]
    end

    def page_defaults
      Nanoc2::PageDefaults.new({ :foo => 'bar' })
    end

    def layouts
      [
        Nanoc2::Layout.new(
          'HEADER <%= @page.content %> FOOTER',
          { :filter => 'erb' },
          '/quux/'
        )
      ]
    end

    def templates
      [
        Nanoc2::Template.new('Content Here', { :foo => 'bar' }, 'default')
      ]
    end

    def code
      Nanoc2::Code.new(
        "class TestEarlyLoadingCodeRouter < Nanoc2::Router\n" +
        "  identifier :early_loading_code_router\n" +
        "  def web_path_for(page)  ; 'web path'  ; end\n" +
        "  def disk_path_for(page) ; 'disk path' ; end\n" +
        "end"
      )
    end

  end

  class TestRouter < Nanoc2::Router

    identifier :test_router

  end

  def test_initialize
    in_dir [ 'tmp' ] do
      # Create temporary site
      create_site('testing')

      in_dir [ 'testing' ] do
        # Test everything okay
        Nanoc2::Site.new(
          :output_dir   => 'output',
          :data_source  => 'filesystem',
          :router       => 'default'
        )

        # Test unknown data source
        assert_raises(Nanoc2::Errors::UnknownDataSourceError) do
          Nanoc2::Site.new(
            :output_dir   => 'output',
            :data_source  => 'kasdflksafjlksdjaklfkjdsjakf',
            :router       => 'default'
          )
        end

        # Test unknown router
        assert_raises(Nanoc2::Errors::UnknownRouterError) do
          Nanoc2::Site.new(
            :output_dir   => 'output',
            :data_source  => 'filesystem',
            :router       => 'kasdflksafjlksdjaklfkjdsjakf'
          )
        end
      end
    end
  end

  def test_initialize_custom_router
    Nanoc2::Site.new(
      :output_dir   => 'output',
      :data_source  => 'early_loading_code_data_source',
      :router       => 'early_loading_code_router'
    )
  end

  def test_load_data
    # Create site with oldschool data source
    site = Nanoc2::Site.new(:data_source => 'test_oldschool_data_source')
    site.load_data

    # Check classes
    assert(site.pages.all? { |p| p.is_a?(Nanoc2::Page) })
    assert(site.page_defaults.is_a?(Nanoc2::PageDefaults))
    assert(site.layouts.all? { |l| l.is_a?(Nanoc2::Layout) })
    assert(site.templates.all? { |t| t.is_a?(Nanoc2::Template) })
    assert(site.code.is_a?(Nanoc2::Code))

    # Check whether site is set
    assert(site.pages.all? { |p| p.site == site })
    assert(site.page_defaults.site == site)
    assert(site.layouts.all? { |l| l.site == site })
    assert(site.templates.all? { |t| t.site == site })
    assert(site.code.site == site)

    # Create site with newschool data source
    site = Nanoc2::Site.new(:data_source => 'test_newschool_data_source')
    site.load_data

    # Check classes
    assert(site.pages.all? { |p| p.is_a?(Nanoc2::Page) })
    assert(site.page_defaults.is_a?(Nanoc2::PageDefaults))
    assert(site.layouts.all? { |l| l.is_a?(Nanoc2::Layout) })
    assert(site.templates.all? { |t| t.is_a?(Nanoc2::Template) })
    assert(site.code.is_a?(Nanoc2::Code))

    # Check whether site is set
    assert(site.pages.all? { |p| p.site == site })
    assert(site.page_defaults.site == site)
    assert(site.layouts.all? { |l| l.site == site })
    assert(site.templates.all? { |t| t.site == site })
    assert(site.code.site == site)

  end

  def test_config
    in_dir [ 'tmp' ] do
      # Create temporary site
      create_site('testing')

      in_dir [ 'testing' ] do
        # Create site
        site = Nanoc2::Site.new(
          :output_dir   => 'custom_output',
          :data_source  => 'test_data_source',
          :router       => 'test_router'
        )

        # Check
        assert_equal('custom_output',     site.config[:output_dir])
        assert_equal('test_data_source',  site.config[:data_source])
        assert_equal('test_router',       site.config[:router])

        # Create site
        site = Nanoc2::Site.new({})

        # Check
        assert_equal('output',      site.config[:output_dir])
        assert_equal('filesystem',  site.config[:data_source])
        assert_equal('default',     site.config[:router])
      end
    end
  end

end
