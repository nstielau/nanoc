module Nanoc2::Filters
  class RDiscount < Nanoc2::Filter

    identifiers :rdiscount

    def run(content)
      require 'rdiscount'

      ::RDiscount.new(content).to_html
    end

  end
end
