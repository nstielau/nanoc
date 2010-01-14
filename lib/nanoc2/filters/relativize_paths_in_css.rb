module Nanoc2::Filters
  class RelativizePathsInCSS < Nanoc2::Filter

    identifier :relativize_paths_in_css

    require 'nanoc2/helpers/link_to'
    include Nanoc2::Helpers::LinkTo

    def run(content)
      content.gsub(/url\((['"]?)(\/.+?)\1\)/) do
        'url(' + $1 + relative_path_to($2) + $1 + ')'
      end
    end

  end
end
