module Nanoc2::Extra::VCSes

  class Mercurial < Nanoc2::Extra::VCS

    identifiers :mercurial, :hg

    def add(filename)
      system('hg', 'add', filename)
    end

    def remove(filename)
      system('hg', 'rm', filename)
    end

    def move(src, dst)
      system('hg', 'mv', src, dst)
    end

  end

end
