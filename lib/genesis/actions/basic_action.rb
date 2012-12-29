module Genesis
  module Actions

    module BasicAction

      def set_opts(opts)
        @opts = opts
        if self.respond_to? :validate_opts
          status, msg = validate_opts
          raise("Invalid action options#{status ? '' : ": #{msg}"}") unless status
          [status, msg]
        else
          [true, 'Options setup success']
        end
      end

    end

  end
end
