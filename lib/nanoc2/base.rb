module Nanoc2

  autoload :Asset,              'nanoc2/base/asset'
  autoload :AssetDefaults,      'nanoc2/base/asset_defaults'
  autoload :AssetRep,           'nanoc2/base/asset_rep'
  autoload :BinaryFilter,       'nanoc2/base/binary_filter'
  autoload :Code,               'nanoc2/base/code'
  autoload :Compiler,           'nanoc2/base/compiler'
  autoload :DataSource,         'nanoc2/base/data_source'
  autoload :Defaults,           'nanoc2/base/defaults'
  autoload :Filter,             'nanoc2/base/filter'
  autoload :Layout,             'nanoc2/base/layout'
  autoload :NotificationCenter, 'nanoc2/base/notification_center'
  autoload :Page,               'nanoc2/base/page'
  autoload :PageDefaults,       'nanoc2/base/page_defaults'
  autoload :PageRep,            'nanoc2/base/page_rep'
  autoload :Plugin,             'nanoc2/base/plugin'
  autoload :Proxy,              'nanoc2/base/proxy'
  autoload :Router,             'nanoc2/base/router'
  autoload :Site,               'nanoc2/base/site'
  autoload :Template,           'nanoc2/base/template'

  require 'nanoc2/base/core_ext'
  require 'nanoc2/base/proxies'

end
