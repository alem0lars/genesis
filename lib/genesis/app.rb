require 'optparse'
require 'rainbow'
require 'ostruct'


module Genesis
  class App
    def initialize(args)
      @opts = OpenStruct.new
      @args = args
      @args_parser = OptionParser.new
      setup_args_parser
    end

    def run
      begin
        # TODO
      rescue ExitRequestException => exc
        puts '>> Exiting'
        unless exc.message.nil?
          puts "\t#{exc.message}"
        end
      rescue Exception => exc
        $stderr.puts('>> Exiting')
        $stderr.puts(exc.message)
      end
    end

    private

    def setup_args_parser
      @args_parser.on('-v', '--version')   { print_version; raise ExitRequestException, nil }
      @args_parser.on('-h', '--help')      { print_help; raise ExitRequestException, nil }
      @args_parser.on('-V', '--verbose')   { @opts.verbose = true }
      @args_parser.on('-q', '--quiet')     { @opts.quiet = true }
      @args_parser.on('-c', '--colorized') { @opts.colors = true }
    end

    def print_version
      puts "Version: #{Genesis::version.color(:cyan)}"
    end
    def print_help
      puts @args_parser.help
    end

  end

  class ExitRequestException < Exception

  end

end
