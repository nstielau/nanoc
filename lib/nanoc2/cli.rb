$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../../vendor/cri/lib'))
require 'cri'

module Nanoc2::CLI # :nodoc:
end

require 'nanoc2/cli/base'
require 'nanoc2/cli/commands'
require 'nanoc2/cli/logger'
