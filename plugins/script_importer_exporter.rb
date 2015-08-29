#===============================================================================
# Filename:    script_importer_exporter.rb
#
# Developer:   Raku (rakudayo@gmail.com)
#              XXXX
#
# Description: This file contains a plugin for the RM Plugin System which 
#  automatically exports all scripts in the Scripts file to plain text Ruby files
#  which can be versioned using a versioning system such as Subversion or Mercurial.
#  When the system shuts down, all data is output into YAML and when the system 
#  is started again, the YAML files are read back into the original Scripts file.
#===============================================================================
class ScriptImporterExporter < PluginBase
  # Register this plugin so that the system knows to execute it
  register self

  # Specify the execution constraints
  # ...None

  def initialize
    super    
  end

  def on_start
    # Set up the directory paths
    $INPUT_DIR  = $PROJECT_DIR + '/' + $SCRIPTS_DIR + '/'
    $OUTPUT_DIR = $PROJECT_DIR + '/' + $DATA_DIR + '/'
    
    print_separator(true)
    puts "  RGSS Script Import"
    print_separator(true)
 
    # Check if the input directory exist
    if not (File.exist? $INPUT_DIR and File.directory? $INPUT_DIR)
      puts_verbose "Input directory #{$INPUT_DIR} does not exist."
      puts_verbose "Nothing to import...skipping import."
      puts_verbose
      return
    end
 
    # Create the output directory if it doesn't exist
    if not (File.exist? $OUTPUT_DIR and File.directory? $OUTPUT_DIR)
      puts "Error: Output directory #{$OUTPUT_DIR} does not exist."
      puts "Hint: Check that the data_dir config option in config.yaml is set correctly."
      puts
      exit
    end
 
    start_time = Time.now
 
    # Import the RGSS scripts from Ruby files
    if File.exist?($INPUT_DIR + $EXPORT_DIGEST_FILE)
      # Load the export digest
      digest = []
      i = 0
      File.open($INPUT_DIR + $EXPORT_DIGEST_FILE, File::RDONLY) do |digestfile|
        digestfile.each do |line|
          line.chomp!
          digest[i] = []
          digest[i][0] = line[0..$COLUMN1_WIDTH-1].rstrip.to_i
          digest[i][1] = line[$COLUMN1_WIDTH..($COLUMN1_WIDTH+$COLUMN2_WIDTH-1)].rstrip
          digest[i][2] = line[($COLUMN1_WIDTH+$COLUMN2_WIDTH)..-1].rstrip
          i += 1
        end
      end
 
      # Find out how many non-empty scripts we have
      num_scripts  = digest.select { |e| e[2].upcase != "EMPTY" }.size
      num_exported = 0
 
      # Create the scripts data structure
      scripts = []
      #for i in (0..digest.length-1)
      digest.each_index do |i|
        # Get the time starting the deflate
        deflate_start_time = Time.now
        
        scripts[i] = []
        scripts[i][0] = digest[i][0]
        scripts[i][1] = digest[i][1]
        scripts[i][2] = ""
        if digest[i][2].upcase != "EMPTY"
          begin
            scriptname = $INPUT_DIR + "/" + digest[i][2]
            File.open(scriptname, File::RDONLY) do |infile|
              scripts[i][2] = infile.read
            end
          rescue Errno::ENOENT
            puts "ERROR:      No such file or directory - #{scriptname.gsub!('//','/')}.\n" +
                 "Suggestion: If you are using a versioning system, check if this is a new\n" + 
                 "RGSS script that was not commited to the repository."
          end
          num_exported += 1
        end
        # Perform the deflate on the compressed script
        scripts[i][2] = Zlib::Deflate.deflate(scripts[i][2])
        # Calculate the elapsed time for the deflate
        deflate_elapsed_time = Time.now - deflate_start_time
        # Build a log string
        str =  "Imported #{digest[i][2].ljust($FILENAME_WIDTH)}(#{num_exported.to_s.rjust(3, '0')}/#{num_scripts.to_s.rjust(3, '0')})"
        str += "         #{deflate_elapsed_time} seconds" if deflate_elapsed_time > 0.0
        puts_verbose str if digest[i][2].upcase != "EMPTY"
      end
 
      # Dump the scripts data structure to the RM's Script file
      File.open($OUTPUT_DIR + "Scripts.#{$DATA_TYPE}", File::WRONLY|File::TRUNC|File::CREAT|File::BINARY) do |outfile|
        Marshal.dump(scripts, outfile)
      end
 
      elapsed_time = Time.now - start_time
 
      print_separator
      puts_verbose "The total import time:  #{elapsed_time} seconds."
      print_separator
    elsif
      puts_verbose "No scripts to import."
    end
 
    puts_verbose
  end

  def on_exit    
    # Set up the directory paths
    $INPUT_DIR  = $PROJECT_DIR + '/' + $DATA_DIR + '/'
    $OUTPUT_DIR = $PROJECT_DIR + '/' + $SCRIPTS_DIR + '/'
    
    print_separator(true)
    puts "  RGSS Script Export"
    print_separator(true)
 
    $STARTUP_TIME = load_startup_time || Time.now
 
    # Check if the input directory exist
    if not (File.exist? $INPUT_DIR and File.directory? $INPUT_DIR)
      puts "Error: Input directory #{$INPUT_DIR} does not exist."
      puts "Hint: Check that the data_dir path in config.yaml is set to the correct path."
      exit
    end
 
    # Create the output directory if it doesn't exist
    if not (File.exist? $OUTPUT_DIR and File.directory? $OUTPUT_DIR)
      recursive_mkdir( $OUTPUT_DIR )
    end
 
    if (not file_modified_since?($INPUT_DIR + "Scripts.#{$DATA_TYPE}", $STARTUP_TIME)) and (File.exist?($SCRIPTS_DIR + "/" + $EXPORT_DIGEST_FILE))
      puts_verbose "No RGSS scripts need to be exported."
      puts_verbose
      return
    end
 
    start_time = Time.now
 
    # Read in the scripts from script file
    scripts = nil
    File.open($INPUT_DIR + "Scripts.#{$DATA_TYPE}", File::RDONLY|File::BINARY) do |infile|
      scripts = Marshal.load(infile)
    end
 
    # Create the export digest
    digest = []
    File.open($OUTPUT_DIR + $EXPORT_DIGEST_FILE, File::WRONLY|File::CREAT|File::TRUNC) do |digestfile|
      scripts.each_index do |i|
        digest[i] = []
        digest[i] << scripts[i][0]
        digest[i] << scripts[i][1]
        digest[i] << generate_filename(scripts[i])
        line = "#{digest[i][0].to_s.ljust($COLUMN1_WIDTH)}#{digest[i][1].ljust($COLUMN2_WIDTH)}#{digest[i][2]}\n"
        #puts line
        digestfile << line
      end
    end
 
    # Find out how many non-empty scripts we have
    num_scripts  = digest.select { |e| e[2].upcase != "EMPTY" }.size
    num_exported = 0
 
    # Save each script to a separate file
    scripts.each_index do |i|
      if digest[i][2].upcase != "EMPTY"
        inflate_start_time = Time.now
        File.open($OUTPUT_DIR + digest[i][2], File::WRONLY|File::CREAT|File::TRUNC|File::BINARY) do |outfile|
          outfile << Zlib::Inflate.inflate(scripts[i][2])
        end
        num_exported += 1
        inflate_elapsed_time =  Time.now - inflate_start_time
        str  = "Exported #{digest[i][2].ljust($FILENAME_WIDTH)}(#{num_exported.to_s.rjust(3, '0')}/#{num_scripts.to_s.rjust(3, '0')})"
        str += "         #{inflate_elapsed_time} seconds" if inflate_elapsed_time > 0.0
        puts_verbose str
 
      end
    end
 
    puts "\n"
 
    elapsed_time = Time.now - start_time
 
    print_separator
    puts_verbose "The total export time:  #{elapsed_time} seconds."
    print_separator
    puts_verbose
  end
end