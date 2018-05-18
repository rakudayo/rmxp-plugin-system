#===============================================================================
# Filename:    plugin_base.rb
#
# Developer:   Raku (rakudayo@gmail.com)
#
# Description: This file contains the PluginBase class which acts as the base
#  class for all plugins developed for the RMXP Plugin System.  Al plugins are
#  provided basic functionality for specifying which other plugins they must
#  be run before or after, as well as methods for calling on startup and on
#  shutdown of the system.
#===============================================================================
require_relative 'rgl/adjacency'
require_relative 'rgl/topsort.rb'

class PluginBase
  @@plugins = []
  @@startup_execution_constraints   = {}
  @@shutdown_execution_constraints  = {}
  
  def initialize
  end

protected
  def self.register(klass)
    @@plugins << klass
  end

  #=====================================================================
  # Method: before
  #---------------------------------------------------------------------
  # Specifies that this plugin should be executed before the plugin with
  # the specified name.
  #---------------------------------------------------------------------
  # plugin_name:  A string with the name of the plugin that this plugin
  #               must execute before on the specified event.
  # event:        The symbol representing the event.  Valid values are
  #               :on_start and :on_exit
  #=====================================================================
  def self.before( plugin_name, event )
    if event == :on_start
	    add_startup_constraint( self.to_s, plugin_name )
    else
      add_shutdown_constraint( self.to_s, plugin_name )
    end
  end
    
  #=====================================================================
  # Method: after
  #---------------------------------------------------------------------
  # Returns the list of plugins to execute according the specified
  # constraints.
  #---------------------------------------------------------------------
  # plugin_name:  A string with the name of the plugin that this plugin
  #               must execute after on the specified event.
  # event:        The symbol representing the event.  Valid values are
  #               :on_start and :on_exit
  #=====================================================================
  def self.after( plugin_name, event )
    if event == :on_start
      add_startup_constraint( plugin_name, self.to_s )
    else
      add_shutdown_constraint( plugin_name, self.to_s )
    end
  end

  def on_start
  end

  def on_exit
  end
  
private
  def self.add_startup_constraint( before, after )
    # Create a new array to store this plugin's constraint list
    @@startup_execution_constraints[ before ] ||= []
 
    # Add the constraint
    @@startup_execution_constraints[ before ] << after
 
    # Remove duplicates
    @@startup_execution_constraints[ before ].uniq!
  end
 
  def self.add_shutdown_constraint( before, after )
    # Create a new array to store this plugin's constraint list
    @@shutdown_execution_constraints[ before ] ||= []
 
    # Add the constraint
    @@shutdown_execution_constraints[ before ] << after
 
    # Remove duplicates
    @@shutdown_execution_constraints[ before ].uniq!
  end

public
  #=====================================================================
  # Method: get_startup_plugin_order
  #---------------------------------------------------------------------
  # .
  #=====================================================================
  def self.get_startup_plugin_order
    # Create a directed acyclic graph
    dag = RGL::DirectedAdjacencyGraph.new
 
    # Add the ordering constraints to the graph
    @@startup_execution_constraints.each_pair do |plugin, after_plugin_list|
      after_plugin_list.each do |after_plugin|
        dag.add_edge( plugin, after_plugin )
      end
    end
 
    # Add all the vertices to the graph
    @@plugins.each do |plugin|
      dag.add_vertex( plugin.to_s )
    end
 
    # Perform a topological sort on the graph
    topsort = dag.topsort_iterator
 
    return topsort.entries
  end
 
  #=====================================================================
  # Method: get_shutdown_plugin_order
  #---------------------------------------------------------------------
  # .
  #=====================================================================
  def self.get_shutdown_plugin_order
    #puts @@shutdown_execution_constraints.inspect
 
    # Create a directed acyclic graph
    dag = RGL::DirectedAdjacencyGraph.new
 
    # Add the ordering constraints to the graph
    @@shutdown_execution_constraints.each_pair do |plugin, after_plugin_list|
      after_plugin_list.each do |after_plugin|
        dag.add_edge( plugin, after_plugin )
      end
    end
 
    # Add all the vertices to the graph
    @@plugins.each do |plugin|
      dag.add_vertex( plugin.to_s )
    end
 
    # Perform a topological sort on the graph
    topsort = dag.topsort_iterator
 
    return topsort.entries
  end
end

