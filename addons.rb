

#================================================
#  Class Extensions/Modifications
#================================================

#-------------------------------------------------------------------------------------
# This change to Hash is critical if we want to version YAML files.  By default, the
# order of hash keys is not guaranteed.  This change modifies the Hash#to_yaml method
# to sort the hash based on key before emitting the YAML for it.
#-------------------------------------------------------------------------------------
class Hash
  # Replacing the to_yaml function so it'll serializes hashes sorted (by their keys)
  def to_yaml( opts = {} )
    YAML::dump( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        sort.each do |k, v|   # <-- here's my addition (the 'sort')
          map.add( k, v )
        end
      end
    end
  end
end


class Dir

  #---------------------------------------------------------
  # Method: recurse
  # Description:  Executes a block for every entry in the
  #   current directory, recursing into subdirectories.
  # Parameters: 
  #   dir - The directory to start from
  #   &block - The block passed by the caller which is
  #            applied to each entry in the directory tree
  #---------------------------------------------------------
  def self.recurse( dir, &block )
    # Get the listing directory
    entries = Dir.entries( dir )
  
    # Remove unwanted entries
    entries = entries.select { |e| e != ".." and 
                                   e != "."  and
                                   e != ".svn" }
                                 
    # Iterate through the entries in this directory
    entries.each do |entry|
      # Execute the block for each entry in this directory
      yield(dir, entry)
    
      # For each directory, recurse
      if File.directory? "#{dir}/#{entry}"
        self.recurse( "#{dir}/#{entry}", &block)
      end
    end
  end
end

