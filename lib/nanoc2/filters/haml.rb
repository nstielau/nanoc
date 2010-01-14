module Nanoc2::Filters
  class Haml < Nanoc2::Filter

    identifiers :haml

    def run(content)
      require 'haml'

      # Get options
      options = @obj_rep.attribute_named(:haml_options) || {}
      options[:filename] = filename

      # Create context
      context = ::Nanoc2::Extra::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns)
    end

  end
end
