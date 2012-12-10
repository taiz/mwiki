require 'mwiki/locale'
require 'mwiki/page'

module MWiki

  class WikiSpace

    def initialize(config, database, syntax)
      @config = config
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
      raise "no such file #{name}" unless exist?(name)
      page = @db.find(name)
      ViewPage.new(@config, page)
    end

    def edit(name)
      if File.exist?(name)
      then page = @db.find(name)
      else page = @db.proxy(name, "")
      end
      EditPage.new(@config, page)
    end

    def create(name)
      page = @db.create(name)
      NewPage.new(@config, page)
    end

    def save(name, text)
      page = @db.find(name) || @db.create(name)
      page.source = text
      page.save()
      ThanksPage.new(@config, name)
    end

    def preview(name, text)
      page = @db.proxy(name, text)
      PreviewPage.new(@config, page)
    end

    def list
      ListPage.new(@config, @db.list_page)
    end

    def delete(name)
      @db.find(name).delete
      DeletePage.new(@config, name)
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

