# encoding: utf-8

module Nanoc3

  # The in-memory representation of a nanoc site. It holds references to the
  # following site data:
  #
  # * {#items}         - the list of items         ({Nanoc3::Item})
  # * {#layouts}       - the list of layouts       ({Nanoc3::Layout})
  # * {#code_snippets} - the list of code snippets ({Nanoc3::CodeSnippet})
  #
  # In addition, each site has a {#config} hash which stores the site
  # configuration.
  #
  # A site also has several helper classes:
  #
  # * {#data_sources} (array of {Nanoc3::DataSource}) - A list of data sources
  #   that are used for loading site data
  #
  # * {#compiler} ({Nanoc3::Compiler}) - The compiler that is used for
  #   compiling items and their representations
  #
  # The physical representation of a {Nanoc3::Site} is usually a directory
  # that contains a configuration file, site data, a rakefile, a rules file,
  # etc. The way site data is stored depends on the data source.
  class Site

    # The default configuration for a data source. A data source's
    # configuration overrides these options.
    DEFAULT_DATA_SOURCE_CONFIG = {
      :type         => 'filesystem_unified',
      :items_root   => '/',
      :layouts_root => '/',
      :config       => {}
    }

    # The default configuration for a site. A site's configuration overrides
    # these options: when a {Nanoc3::Site} is created with a configuration
    # that lacks some options, the default value will be taken from
    # `DEFAULT_CONFIG`.
    DEFAULT_CONFIG = {
      :text_extensions    => %w( css erb haml htm html js less markdown md php rb sass txt xml ),
      :output_dir         => 'output',
      :data_sources       => [ {} ],
      :index_filenames    => [ 'index.html' ],
      :enable_output_diff => false
    }

    # The name of the file where checksums will be stored.
    CHECKSUMS_FILE_NAME = 'tmp/checksums'

    # The site configuration. The configuration has the following keys:
    #
    # * `text_extensions` ({Array<String>}) - A list of file extensions that
    #   will cause nanoc to threat the file as textual instead of binary. When
    #   the data source finds a content file with an extension that is
    #   included in this list, it will be marked as textual.
    #
    # * `output_dir` ({String}) - The directory to which compiled items will
    #   be written. This path is relative to the current working directory,
    #   but can also be an absolute path.
    #
    # * `data_sources` ({Array<Hash>}) - A list of data sources for this site.
    #   See below for documentation on the structure of this list. By default,
    #   there is only one data source of the filesystem  type mounted at `/`.
    #
    # * `index_filenames` ({Array<String>}) - A list of filenames that will be
    #   stripped off full item paths to create cleaner URLs. For example,
    #   `/about/` will be used instead of `/about/index.html`). The default
    #   value should be okay in most cases.
    #
    # * `enable_output_diff` ({Boolean}) - True when diffs should be generated
    #   for the compiled content of this site; false otherwise.
    #
    # The list of data sources consists of hashes with the following keys:
    #
    # * `:type` ({String}) - The type of data source, i.e. its identifier.
    #
    # * `:items_root` ({String}) - The prefix that should be given to all
    #   items returned by the {#items} method (comparable to mount points
    #   for filesystems in Unix-ish OSes).
    #
    # * `:layouts_root` ({String}) - The prefix that should be given to all
    #   layouts returned by the {#layouts} method (comparable to mount
    #   points for filesystems in Unix-ish OSes).
    #
    # * `:config` ({Hash}) - A hash containing the configuration for this data
    #   source. nanoc itself does not use this hash. This is especially
    #   useful for online data sources; for example, a Twitter data source
    #   would need the username of the account from which to fetch tweets.
    #
    # @return [Hash] The site configuration
    attr_reader :config

    # @return [String] The checksum of the site configuration that was in
    #   effect during the previous site compilation
    attr_accessor :old_config_checksum

    # @return [String] The current, up-to-date checksum of the site
    #   configuration
    attr_reader   :new_config_checksum

    # @return [String] The checksum of the rules file that was in effect
    #   during the previous site compilation
    attr_accessor :old_rules_checksum

    # @return [String] The current, up-to-date checksum of the rules file
    attr_reader   :new_rules_checksum

    # @return [Proc] The code block that will be executed after all data is
    # loaded but before the site is compiled
    attr_accessor :preprocessor

    # Creates a site object for the site specified by the given
    # `dir_or_config_hash` argument.
    #
    # @param [Hash, String] dir_or_config_hash If a string, contains the path
    # to the site directory; if a hash, contains the site configuration.
    def initialize(dir_or_config_hash)
      @new_checksums = {}

      build_config(dir_or_config_hash)

      @code_snippets_loaded = false
      @items_loaded         = false
      @layouts_loaded       = false
    end

    # Returns the compiler for this site. Will create a new compiler if none
    # exists yet.
    #
    # @return [Nanoc3::Compiler] The compiler for this site
    def compiler
      @compiler ||= Compiler.new(self)
    end

    # Returns the data sources for this site. Will create a new data source if
    # none exists yet.
    #
    # @return [Array<Nanoc3::DataSource>] The list of data sources for this
    # site
    #
    # @raise [Nanoc3::Errors::UnknownDataSource] if the site configuration
    # specifies an unknown data source
    def data_sources
      @data_sources ||= begin
        @config[:data_sources].map do |data_source_hash|
          # Get data source class
          data_source_class = Nanoc3::DataSource.named(data_source_hash[:type])
          raise Nanoc3::Errors::UnknownDataSource.new(data_source_hash[:type]) if data_source_class.nil?

          # Warn about deprecated data sources
          # TODO [in nanoc 4.0] remove me
          case data_source_hash[:type]
            when 'filesystem'
              warn "Warning: the 'filesystem' data source has been renamed to 'filesystem_verbose'. Using 'filesystem' will work in nanoc 3.1.x, but it will likely not work anymore in a future release of nanoc. Please update your data source configuration and replace 'filesystem' with 'filesystem_verbose'."
            when 'filesystem_combined', 'filesystem_compact'
              warn "Warning: the 'filesystem_combined' and 'filesystem_compact' data source has been merged into the new 'filesystem_unified' data source. Using 'filesystem_combined' and 'filesystem_compact' will work in nanoc 3.1.x, but it will likely not work anymore in a future release of nanoc. Please update your data source configuration and replace 'filesystem_combined' and 'filesystem_compact with 'filesystem_unified'."
          end

          # Create data source
          data_source_class.new(
            self,
            data_source_hash[:items_root],
            data_source_hash[:layouts_root],
            data_source_hash[:config] || {}
          )
        end
      end
    end

    # Loads the site data. This will query the {Nanoc3::DataSource} associated
    # with the site and fetch all site data. The site data is cached, so
    # calling this method will not have any effect the second time, unless
    # the `force` parameter is true.
    #
    # @param [Boolean] force If true, will force load the site data even if it
    # has been loaded before, to circumvent caching issues
    #
    # @return [void]
    def load_data(force=false)
      # Don't load data twice
      return if instance_variable_defined?(:@data_loaded) && @data_loaded && !force

      # Load all data
      load_code_snippets(force)
      data_sources.each { |ds| ds.use }
      load_rules
      load_items
      load_layouts
      data_sources.each { |ds| ds.unuse }

      # Preprocess
      setup_child_parent_links
      preprocessor_context.instance_eval(&preprocessor) unless preprocessor.nil?
      link_everything_to_site
      setup_child_parent_links
      build_reps
      route_reps

      # Done
      @data_loaded = true
    end

    # Returns this site’s code snippets.
    #
    # @return [Array<Nanoc3::CodeSnippet>] The list of code snippets in this
    # site
    #
    # @raise [Nanoc3::Errors::DataNotYetAvailable] if the site data hasn’t
    # been loaded yet (call {#load_data} to load the site data)
    def code_snippets
      raise Nanoc3::Errors::DataNotYetAvailable.new('Code snippets', false) unless @code_snippets_loaded
      @code_snippets
    end

    # Returns this site’s items.
    #
    # @return [Array<Nanoc3::Item>] The list of items in this site
    #
    # @raise [Nanoc3::Errors::DataNotYetAvailable] if the site data hasn’t
    # been loaded yet (call {#load_data} to load the site data)
    def items
      raise Nanoc3::Errors::DataNotYetAvailable.new('Items', true) unless @items_loaded
      @items
    end

    # Returns this site’s layouts.
    #
    # @return [Array<Nanoc3::Layouts>] The list of layout in this site
    #
    # @raise [Nanoc3::Errors::DataNotYetAvailable] if the site data hasn’t
    # been loaded yet (call {#load_data} to load the site data)
    def layouts
      raise Nanoc3::Errors::DataNotYetAvailable.new('Layouts', true) unless @layouts_loaded
      @layouts
    end

    # Stores the checksums into the checksums file.
    #
    # @return [void]
    def store_checksums
      # Store
      FileUtils.mkdir_p(File.dirname(CHECKSUMS_FILE_NAME))
      store = PStore.new(CHECKSUMS_FILE_NAME)
      store.transaction do
        store[:checksums] = @new_checksums || {}
      end
    end

  private

    # Returns the Nanoc3::CompilerDSL that should be used for this site.
    def dsl
      @dsl ||= Nanoc3::CompilerDSL.new(self)
    end

    # Loads this site’s code and executes it.
    def load_code_snippets(force=false)
      # Don't load code snippets twice
      return if @code_snippets_loaded and !force

      # Get code snippets
      @code_snippets = Dir['lib/**/*.rb'].sort.map do |filename|
        Nanoc3::CodeSnippet.new(
          File.read(filename),
          filename,
          :checksum => checksum_for(filename)
        )
      end

      # Set checksums
      @code_snippets.each do |cs|
        cs.old_checksum = old_checksum_for(:code_snippet, cs.filename)
        @new_checksums[ [ :code_snippet, cs.filename ] ] = cs.new_checksum
      end

      # Execute code snippets
      @code_snippets.each { |cs| cs.load }

      @code_snippets_loaded = true
    end

    # Loads this site’s rules.
    def load_rules
      # Find rules file
      rules_filename = [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].find { |f| File.file?(f) }
      raise Nanoc3::Errors::NoRulesFileFound.new if rules_filename.nil?

      # Get rule data
      @rules = File.read(rules_filename)
      @new_rules_checksum = checksum_for(rules_filename)
      @old_rules_checksum = old_checksum_for(:misc, 'Rules')
      @new_checksums[ [ :misc, 'Rules' ] ] = @new_rules_checksum

      # Load DSL
      dsl.instance_eval(@rules, "./#{rules_filename}")
    end

    # Loads this site’s items, sets up item child-parent relationships and
    # builds each item's list of item representations.
    def load_items
      @items = []
      data_sources.each do |ds|
        items_in_ds = ds.items
        items_in_ds.each { |i| i.identifier = File.join(ds.items_root, i.identifier) }
        @items.concat(items_in_ds)
      end

      # Set checksums
      @items.each do |i|
        i.old_checksum = old_checksum_for(:item, i.identifier)
        @new_checksums[ [ :item, i.identifier ] ] = i.new_checksum
      end

      @items_loaded = true
    end

    # Loads this site’s layouts.
    def load_layouts
      @layouts = []
      data_sources.each do |ds|
        layouts_in_ds = ds.layouts
        layouts_in_ds.each { |i| i.identifier = File.join(ds.layouts_root, i.identifier) }
        @layouts.concat(layouts_in_ds)
      end

      # Set checksums
      @layouts.each do |l|
        l.old_checksum = old_checksum_for(:layout, l.identifier)
        @new_checksums[ [ :layout, l.identifier ] ] = l.new_checksum
      end

      @layouts_loaded = true
    end

    # Links items, layouts and code snippets to the site.
    def link_everything_to_site
      @items.each         { |i|  i.site  = self }
      @layouts.each       { |l|  l.site  = self }
      @code_snippets.each { |cs| cs.site = self }
    end

    # Fills each item's parent reference and children array with the
    # appropriate items.
    def setup_child_parent_links
      # Clear all links
      @items.each do |item|
        item.parent = nil
        item.children = []
      end

      @items.each do |item|
        # Get parent
        parent_identifier = item.identifier.sub(/[^\/]+\/$/, '')
        parent = @items.find { |p| p.identifier == parent_identifier }
        next if parent.nil? or item.identifier == '/'

        # Link
        item.parent = parent
        parent.children << item
      end
    end

    # Creates the representations of all items as defined by the compilation
    # rules.
    def build_reps
      @items.each do |item|
        # Find matching rules
        matching_rules = self.compiler.item_compilation_rules.select { |r| r.applicable_to?(item) }
        raise Nanoc3::Errors::NoMatchingCompilationRuleFound.new(item) if matching_rules.empty?

        # Create reps
        rep_names = matching_rules.map { |r| r.rep_name }.uniq
        rep_names.each do |rep_name|
          item.reps << ItemRep.new(item, rep_name)
        end
      end
    end

    # Determines the paths of all item representations.
    def route_reps
      reps = @items.map { |i| i.reps }.flatten
      reps.each do |rep|
        # Find matching rule
        rule = self.compiler.routing_rule_for(rep)
        raise Nanoc3::Errors::NoMatchingRoutingRuleFound.new(rep) if rule.nil?

        # Get basic path by applying matching rule
        basic_path = rule.apply_to(rep)
        next if basic_path.nil?

        # Get raw path by prepending output directory
        rep.raw_path = self.config[:output_dir] + basic_path

        # Get normal path by stripping index filename
        rep.path = basic_path
        self.config[:index_filenames].each do |index_filename|
          if rep.path[-index_filename.length..-1] == index_filename
            # Strip and stop
            rep.path = rep.path[0..-index_filename.length-1]
            break
          end
        end
      end
    end

    # Builds the configuration hash based on the given argument. Also see
    # {#initialize} for details.
    def build_config(dir_or_config_hash)
      if dir_or_config_hash.is_a? String
        # Read config from config.yaml in given dir
        config_path = File.join(dir_or_config_hash, 'config.yaml')
        @config = DEFAULT_CONFIG.merge(YAML.load_file(config_path).symbolize_keys)
        @config[:data_sources].map! { |ds| ds.symbolize_keys }

        @new_config_checksum = checksum_for('config.yaml')
        @new_checksums[ [ :misc, 'config.yaml' ] ] = @new_config_checksum
      else
        # Use passed config hash
        @config = DEFAULT_CONFIG.merge(dir_or_config_hash)
        @new_config_checksum = nil
      end

      # Build checksum
      @old_config_checksum = old_checksum_for(:misc, 'config.yaml')

      # Merge data sources with default data source config
      @config[:data_sources].map! { |ds| DEFAULT_DATA_SOURCE_CONFIG.merge(ds) }
    end

    # Returns a preprocessor context, creating one if none exists yet.
    def preprocessor_context
      @preprocessor_context ||= Nanoc3::Context.new({
        :site    => self,
        :config  => self.config,
        :items   => self.items,
        :layouts => self.layouts
      })
    end

    # Returns the checksums, loads the checksums from the cached checksums
    # file first if necessary. The checksums returned is a hash in th following
    # format:
    #
    #     {
    #       [ :layout,       '/identifier/'    ] => checksum,
    #       [ :item,         '/identifier/'    ] => checksum,
    #       [ :code_snippet, 'lib/filename.rb' ] => checksum,
    #     }
    def checksums
      return @checksums if @checksums_loaded

      if !File.file?(CHECKSUMS_FILE_NAME)
        @checksums = {}
      else
        require 'pstore'
        store = PStore.new(CHECKSUMS_FILE_NAME)
        store.transaction do
          @checksums = store[:checksums] || {}
        end
      end

      @checksums_loaded = true
      @checksums
    end

    # Returns the old checksum for the given object.
    def old_checksum_for(type, identifier)
      key = [ type, identifier ]
      checksums[key]
    end

    # Returns a checksum of the given filenames
    # FIXME duplicated
    def checksum_for(*filenames)
      require 'digest'
      filenames.flatten.map do |filename|
        digest = Digest::SHA1.new
        File.open(filename, 'r') do |io|
          until io.eof
            data = io.readpartial(2**10)
            digest.update(data)
          end
        end
        digest.hexdigest
      end.join('-')
    end

  end

end
