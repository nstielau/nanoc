module Nanoc2::Filters
  class BlueCloth < Nanoc2::Filter

    identifiers :bluecloth

    def run(content)
      require 'bluecloth'

      ::BlueCloth.new(content).to_html
    end

  end
end
