module Nanoc2::Filters
  class Erubis < Nanoc2::Filter

    identifiers :erubis

    def run(content)
      require 'erubis'

      # Get result
      ::Erubis::Eruby.new(content).evaluate(assigns)
    end

  end
end
