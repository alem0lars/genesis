module Genesis
  module Actions

    module BasicAction

      def set_opts(opts)
        @opts = opts
        if self.respond_to? :validate_opts
          status, msg = validate_opts
          unless status
            if msg
              raise "Invalid action options: #{msg}"
            else
              raise "Invalid action options"
            end
          end
          [status, msg]
        else
          [true, 'Options setup success']
        end
      end

    end

  end
end
