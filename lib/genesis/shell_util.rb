module Genesis
  module ShellUtil

    # Print in the provided out_dev the provided msg
    # @param msg [String] message to be printed
    # @param opts [OpenStruct] options
    # @param out_dev [IO] output devices (defaults to $stdout)
    # @return [String] the message printed
    def self.prnt(msg, opts = OpenStruct.new(:quiet => false), out_dev = $stdout)
      out_dev.puts(msg) unless opts.quiet
      msg
    end

    # Execute the provided cmd
    # @param cmd [String] command to be executed
    # @return [Boolean] execution success or failure
    def self.execute(cmd)
      system cmd
      $?.success?
    end

  end
end
