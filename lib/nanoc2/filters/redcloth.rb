module Nanoc2::Filters
  class RedCloth < Nanoc2::Filter

    identifiers :redcloth

    def run(content)
      require 'redcloth'

      # Get result
      ::RedCloth.new(content).to_html
    end

  end
end
