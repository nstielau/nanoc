Nanoc.load_file('base', 'plugin.rb')

module Nanoc
  class Filter < Plugin

    def initialize(page, pages, config, site)
      @page   = page
      @pages  = pages
      @config = config
      @site   = site
    end

    def run(content)
      error 'ERROR: Filter#run must be overridden'
    end

  end
end