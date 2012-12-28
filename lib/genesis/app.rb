require 'optparse'
require 'ostruct'


module Genesis
  class App

    def initialize(args, actions = [])
      @actions = {}
      actions.each { |action| register(action) }

      @opts = OpenStruct.new

      @args = args
      @args_parser = OptionParser.new
    end

    def opts
      @opts
    end

    def run
      status, msg = begin
        setup_args_parser
        @args_parser.parse!(@args)
        process_opts
        [true, nil]
      rescue OptionParser::MissingArgument => exc
        [false, exc.message.capitalize]
      rescue Exception => exc
        [false, exc.message]
      end

      print_starting(status ? $stdout : $stderr)
      if status
        $stdout.puts(msg) unless msg.nil?

        print_version if @opts.print_version
        print_help if @opts.print_help

        if @opts.action_name
          if @actions.has_key?(@opts.action_name)
            status, msg = execute_set_opts
            if status
              status, msg = execute_action
            end
          else
            $stdout.puts("Invalid action") unless @opts.quiet
          end
          if status
            status_str = 'Action successfully finished'
            $stdout.puts(">> #{@opts.colors ? status_str.color(:green) : status_str}: #{msg}") unless @opts.quiet
          else
            status_str = 'Action failed'
            $stderr.puts(">> #{@opts.colors ? status_str.color(:red) : status_str}: #{msg}") unless @opts.quiet
          end
        end
      else
        $stderr.puts(msg) unless msg.nil?
        print_help $stderr
      end
      print_exiting(status ? $stdout : $stderr)
    end

    private

    def setup_args_parser
      @args_parser.on('-v', '--version', "Print the current version") { @opts.print_version = true }
      @args_parser.on('-h', '--help', "Print the help") { @opts.print_help = true }
      @args_parser.on('-V', '--verbose', "Be more verbose") { @opts.verbose = true }
      @args_parser.on('-q', '--quiet', "Suppress output") { @opts.quiet = true }
      @args_parser.on('-c', '--no-colors', "Turn off colors") { @opts.colors = false }
      @args_parser.on('-a', '--action action', String, "Action to execute") { |a| @opts.action_name = a }
      @args_parser.on('-o', '--action-opts action_opts', Array, "Action options") { |o| @opts.action_opts = o }
    end
    def process_opts
      @opts.colors = true if @opts.colors.nil?
      @opts.verbose = false if @opts.quiet
      if @opts.action_name
        @opts.action_name = @opts.action_name.to_sym
      else
        raise(OptionParser::InvalidOption, '-o needs -a') if @opts.action_opts
      end
      unless @opts.action_opts
        @opts.action_opts = []
      end

      if @opts.action_name.nil? && @opts.print_version.nil? && @opts.print_help.nil?
        raise(OptionParser::MissingArgument, '-a or -v or -h')
      end
    end

    def print_version
      version_str = @opts.colors ? Genesis::version.color(:cyan) : Genesis::version
      puts @opts.quiet ? version_str : "Version: #{version_str}"
    end
    def print_help(out_dev = $stdout)
      out_dev.puts(@args_parser.help) unless @opts.quiet
    end

    def print_starting(out_dev = $stdout)
      genesis_str = @opts.colors ? 'Genesis'.color(:yellow) : 'Genesis'
      out_dev.puts(">> Starting #{genesis_str}") unless @opts.quiet
    end
    def print_exiting(out_dev = $stdout)
      genesis_str = @opts.colors ? 'Genesis'.color(:yellow) : 'Genesis'
      out_dev.puts(">> Exiting from #{genesis_str}") unless @opts.quiet
    end

    def register(action)
      if action.respond_to?(:on_register)
        action_info = action.on_register

        format_correct = action.respond_to?(:execute) && action.respond_to?(:set_opts)
        if format_correct
          format_correct =
              action_info.respond_to?(:has_key?) &&
              action_info.has_key?(:name)
        end

        if format_correct
          @actions[action_info[:name]] = action_info
          @actions[action_info[:name]][:executor] = Proc.new { action.execute }
          @actions[action_info[:name]][:set_opts] = Proc.new { |opts| action.set_opts(opts) }
          @actions[action_info[:name]].delete(:name)
        end
      end
    end

    def execute_set_opts
      def_success_msg, def_fail_msg = 'validation success', 'validation error'
      begin
        status, msg = @actions[@opts.action_name][:set_opts].call(@opts.dup)
        if status.nil?
          [true, def_success_msg]
        else
          if msg.nil?
            msg = status ? def_success_msg : def_fail_msg
          end
          [status, msg]
        end
      rescue Exception => exc
        [false, exc.message.capitalize]
      end
    end

    def execute_action
      def_success_msg, def_fail_msg = 'be happy', 'don\'t be too sad'
      begin
        status, msg = @actions[@opts.action_name][:executor].call
        if status.nil?
          [true, def_success_msg]
        else
          if msg.nil?
            msg = status ? def_success_msg : def_fail_msg
          end
          [status, msg]
        end
      rescue Exception => exc
        [false, exc.message.capitalize]
      end
    end
  end

end
