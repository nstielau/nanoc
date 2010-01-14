module Nanoc2::Filters
  class Markaby < Nanoc2::Filter

    identifiers :markaby

    def run(content)
      require 'markaby'

      # Get result
      ::Markaby::Builder.new(assigns).instance_eval(content).to_s
    end

  end
end
