#! ruby -Ks

require 'pp'

# Add $LOAD_PATH and set $KCODE
load './mwikirc.rb'
setup_enviroment
require 'mwiki'

# load context
context = load_mwiki_context

# process cgi
# context = config, database, syntax
MWiki::MCGI.main context

