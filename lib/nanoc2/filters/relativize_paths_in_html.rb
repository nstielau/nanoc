module Nanoc2::Filters
  class RelativizePathsInHTML < Nanoc2::Filter

    identifier :relativize_paths_in_html

    require 'nanoc2/helpers/link_to'
    include Nanoc2::Helpers::LinkTo

    def run(content)
      content.gsub(/(src|href)=(['"]?)(\/.+?)\2([ >])/) do
        $1 + '=' + $2 + relative_path_to($3) + $2 + $4
      end
    end

  end
end
