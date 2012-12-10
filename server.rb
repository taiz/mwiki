require 'webrick'

rrr = WEBrick::HTTPServlet::CGIHandler::Ruby
$ruby = $ruby || rrr

module WEBrick
  module HTTPServlet
    FileHandler.add_handler("rb", CGIHandler)
  end
end

def start_webrick(config = {})
  conf = {
    :Port => 9999,
    :CGIInterpreter => $ruby,
    :DocumentRoot => File.dirname( File.expand_path(__FILE__) )
  }
  config.update(conf)  
  server = WEBrick::HTTPServer.new(config)
  yield server if block_given?
  ['INT', 'TERM'].each {|signal| 
    trap(signal) {server.shutdown}
  }
  server.start
end

start_webrick {|server|
  cgi_dir = File.dirname( File.expand_path(__FILE__) )
  server.mount("/mwiki", WEBrick::HTTPServlet::FileHandler, cgi_dir + "/index.rb")
}
