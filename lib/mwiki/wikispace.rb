require 'mwiki/locale'

module MWiki

  class WikiSpace

    def initialize(config, database, syntax)
      @config   = config
      @db = database
      @db.syntax = syntax
    end

    def locale
      @config.locale
    end

    def valid?(name)
      @db.valid?(name)
    end

    def exist?(name)
      @db.exist?(name)
    end

    def view(name)
      page = @db.find(name)
      ViewPage.new(@config, page)
    end

    def edit(name)
      page = @db.find(name)
      EditPage.new(@config, page)
    end

    def create(name)
      page = @db.create(name)
      NewPage.new(@config, page)
    end

    def save(name, text)
      page = @db.find(name) || @db.create(name)
      page.source = text
      page.save(page)
      ThanksPage.new(@config, name)
    end

    def preview(name, text)
      page = @db.create(name)
      page.source = text
      PreviewPange.new(@config, page)
    end

    def search(query, regexps)
      pages = @db.find_all(query, regexps)
      SearchResultPage.new(@config, pages)
    end

    def search_error(query, err)
      SearchErroPage.new(@config, query, err)
    end

  end

end

