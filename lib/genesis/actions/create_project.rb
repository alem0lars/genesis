require 'fileutils'


module Genesis
  module Actions

    class CreateProject
      include Genesis::Actions::BasicAction
      include Genesis::ShellUtil

      def initialize
        @info = OpenStruct.new
      end

      def on_register
        { :name => :create_project }
      end

      def execute
        Either.chain do
          bind -> { setup_basic_project }
          bind -> { setup_repo }
        end
      end

      private

      def setup_basic_project
        @info.prj_name = ask('Project name? ') do |q|
          q.validate = /[A-Za-z0-9\-\.@]{2,}/
        end

        @info.base_dir_pth = Pathname.new(ask('Project base directory? ') do |q|
          q.default = '/usr/local/archive/projects'
        end)
        @info.prj_pth = @info.base_dir_pth.join(@info.prj_name)

        if @info.exists?
          FileUtils.makedirs @info.prj_pth, :verbose => true
          prnt('Basic project informations successfully set up', @opts)
        else
          Failure("Path #{@info.prj_pth} already exists")
        end
      end

      def setup_repo
        if agree('With git? ')
          Either.chain do
            bind ->          { find_git_handler }
            bind ->(handler) { handler.setup }
            bind ->(handler) { use_git_handler(handler) }
          end
        else
          true
        end
      end

      def find_git_handler
        handler = AVAIL_GIT_HANDLERS.detect { |h| ask("Use #{h.name}? ") }
        if handler
          prnt("Using the git handler: #{handler.name}", @opts)
          handler.new(@info)
        else
          Failure('Valid git handler not found')
        end
      end

      def use_git_handler(handler)
        Either.chain do
          bind ->         { handler.git_init }
          bind ->         { handler.git_add_remote }
          bind ->         { handler.git_sync_with_remote }
          bind ->(status) {
            use_services = Success(handler).
              bind -> { handler.has_services }.
              bind -> {
                prnt("#{handler.name} provides these additional services:\n"\
                    "#{handler.ls_services}", @opts)
                agree("Use #{handler.name} services?")
              }
            use_services.success? ? handler.use_services : status
          }
        end
      end

    end
  end
end
