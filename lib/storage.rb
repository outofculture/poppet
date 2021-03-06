require 'rubygems'
require 'json'
require 'fileutils'
require 'pathname'
require 'lib/timestamp'
require 'lib/execute'
require 'lib/struct'

module Poppet
  module Storage
    def self.file(name, &blk)
      make_dir_for( name )
      File.open(name, 'w', &blk)
    end

    def self.make_dir_for(name)
      FileUtils.mkdir_p( File.dirname(name) )
    end

    def self.expected_errors
      [JSON::ParserError, Poppet::Execute::Error]
    end

    def self.glob( glob, errors = expected_errors )
      Dir.glob( glob ).sort.each do |input_filename|
        begin
          input_filename = Pathname.new(input_filename).realpath.to_s
          yield(input_filename)
        rescue *errors => e
          STDERR.puts( "While processing #{input_filename}:" )
          STDERR.puts( e )
          next
        end
      end
    end

    def self.timestamped_file(dir, &blk)
      self.file(File.join(dir, 'by_time', Poppet::Timestamp.now), &blk)
    end

    def self.map_files( glob, filter, target_dir )
      self.glob( glob ) do |input_filename|
        output_filename = File.join( target_dir, File.basename( input_filename ) )
        make_dir_for( output_filename )
        content = Poppet::Execute.execute( "#{filter} < #{input_filename.inspect}" )
        File.open( output_filename, "w" ){|f| f.puts(content) }
      end
    end

    def self.name_by( glob, struct_keys, target_dir )
      self.glob( glob ) do |input_filename|
        data = JSON.parse( File.read( input_filename ) )
        name = Poppet::Struct.by_keys(data, struct_keys)

        raise "name not found" unless name && name != ""

        output_filename = File.join( target_dir, name )

        if File.symlink?(output_filename)
          current_dest = File.readlink(output_filename)
          next if current_dest == input_filename
          File.delete(output_filename)
        end
        make_dir_for( output_filename )
        File.symlink( input_filename, output_filename)
      end
    end

  end
end
