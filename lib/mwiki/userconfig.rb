require 'mwiki/exception'

module MWiki

  class UserConfig
    def self.parse(hash, category)
      conf = new(hash, category)
      yield conf
      conf.check_unknown_options
    end

    def initialize(hash, category)
      @config   = hash.dup
      @category = category
      @refered  = []
    end

    def get(key)
      @refered << key
      return nil unless @config.key?(key)
      if block_given?
        yield(@config[key])
      else
        @config[key]
      end
    end

    alias :[] :get

    def get_required(key)
      required! key
      get key
    end

    def required!(key)
      unless @config.key?(key)
        raise ConfigError, "Config Error: not set: #{@category}.#{key}"
      end
    end

    def exclusive!(*keys)
      if keys.map {|k| @config.key?(k) }.select {|b| b}.size > 1
        raise ConfigError,
          keys.map {|k| "#{@category}.#{k}" }.join(' and ') + ' are exclusive'
      end
    end

    def select!(*keys)
      exclusive! keys
      if keys.all? {|k| not @config.key?(k)}
        raise ConfigError,
          "at least 1 key required: " +
          keys.map {|k| "#{@category}.#{k}" }.join(', ')
      end
    end

    def check_unknown_options
      unknown = (@config.keys  - @refered).uniq
      unless unknown.empty?
        raise ConfigError,
          'Mwiki Configuration Error: unknown keys: ' +
            unknown.map {|k| "#{@category}.#{k}" }.join(', ')
      end
    end
  end
end
