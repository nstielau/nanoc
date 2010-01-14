module Nanoc2::Extra::VCSes

  class Bazaar < Nanoc2::Extra::VCS

    identifiers :bazaar, :bzr

    def add(filename)
      system('bzr', 'add', filename)
    end

    def remove(filename)
      system('bzr', 'rm', filename)
    end

    def move(src, dst)
      system('bzr', 'mv', src, dst)
    end

  end

end
