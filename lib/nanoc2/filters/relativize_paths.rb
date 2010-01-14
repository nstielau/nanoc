module Nanoc2::Filters
  class RelativizePaths < Nanoc2::Filter

    identifier :relativize_paths

    def run(content)
      raise RuntimeError.new(
        "The relativize_paths filter itself does not exist anymore. " +
        "If you want to relativize paths in HTML, use the " +
        "relativize_paths_in_html filter; if you want to relativize paths " +
        "in CSS, use the relativize_paths_in_css filter."
      )
    end

  end
end
