#===============================================================================
# Filename:    start_rmxp.rb
#
# Developer:   Raku (rakudayo@gmail.com)
#
# Description: This script creates all plugins in the Plugins directory and
# executes their on_start event methods and starts RMXP.  When RMXP is closed,
# the on_exit event method of each plugin is called.
#===============================================================================

# Setup the project directory from the command-line argument
OS_VERSION = `ver`.strip
$PROJECT_DIR = ARGV[0]
if OS_VERSION.index( "Windows XP" )
  $PROJECT_DIR = String.new( $PROJECT_DIR )
elsif OS_VERSION.index( "Windows" )
  $PROJECT_DIR = String.new( $PROJECT_DIR ).gsub! "/", "\\"
end


require './common'
require './plugin_base'

#######################################
#        LOCAL METHODS
#######################################

#=====================================================================
# Method: get_plugin_order
#---------------------------------------------------------------------
# Returns the list of plugins to execute according the specified
# constraints.
#---------------------------------------------------------------------
# event:  The symbol representing the event.  Valid values are
#         :on_start and :on_shutdown
#=====================================================================
def get_plugin_order( event )
	if event == :on_start
	  return PluginBase::get_startup_plugin_order
	else
	  return PluginBase::get_shutdown_plugin_order
	end
end


#######################################
#             SCRIPT
#######################################

# Make sure RMXP isn't already running
exit if check_for_rmxp(true)

# Get the list of plugins in the plugin directory
plugins = Dir.entries( "plugins" )
plugins = plugins.select { |filename| File.extname(filename) == ".rb" }

# FIX: For TextMate's annoying habit of creating backup files automatically
#      that still have the .rb extension.
plugins = plugins.select { |filename| filename.index("._") != 0 }

# Evaluate each plugin
plugins.each do |plugin|
  plugin_path = "plugins\\" + plugin
  File.open( plugin_path, "r+" ) do |infile|
    code = infile.read( File.size( plugin_path ) )
    eval( code )
  end
end

# Get the list of plugins in the startup order
plugins = get_plugin_order( :on_start )

# Create each plugin object
plugins.collect! { |plugin| eval( plugin + ".new" ) }

# Execute each plugin's on_start event
plugins.each do |plugin|
  plugin.on_start
end

# Dump the sytem time at startup into a file to read later
dump_startup_time

# Definitely do not want the user to close the command window
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
puts "!!!DO NOT CLOSE THIS COMMAND WINDOW!!!"
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
puts_verbose

# Start RMXP
command = 'START /B /WAIT /D"' + $PROJECT_DIR + '" Game.rxproj'
system(command)

# Get the list of plugins in the shutdown order
plugins = get_plugin_order( :on_exit )

# Create each plugin object
plugins.collect! {|plugin| eval( plugin + ".new" )}

# Execute each plugin's on_exit event
plugins.each do |plugin|
  plugin.on_exit
end

# Delete the startup timestamp
load_startup_time(true)