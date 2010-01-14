class CensorFilter < Nanoc2::Filter

  identifier :censor

  def run(content)
    content.gsub('sucks', 'rocks')
  end

end
