module Nanoc2::Filters
  class Maruku < Nanoc2::Filter

    identifiers :maruku

    def run(content)
      require 'maruku'

      # Get result
      ::Maruku.new(content).to_html
    end

  end
end
