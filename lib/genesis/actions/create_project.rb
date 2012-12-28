module Genesis
  module Actions

    class CreateProject
      include Genesis::Actions::BasicAction

      def on_register
        { :name => :create_project }
      end

      def validate_opts
        # TODO
        true
      end

      def execute
        # TODO
        true
      end

    end

  end
end
