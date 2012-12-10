require 'erb'

module MWiki

  module ErbUtils

    def run_erb(template_dir, template_id)
      erb = ERB.new(get_template(template_dir, template_id))
      erb.result(binding())
    end

    def get_template(templdir, id)
      File.read("#{templdir}/#{id}.html.erb").gsub(/^\s*\.include (\w+)\b/) do
        get_template(templdir, $1)
      end
    end

  end

end
