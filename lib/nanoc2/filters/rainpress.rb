module Nanoc2::Filters
  class Rainpress < Nanoc2::Filter

    identifier :rainpress

    def run(content)
      require 'rainpress'

      ::Rainpress.compress(content)
    end

  end
end
