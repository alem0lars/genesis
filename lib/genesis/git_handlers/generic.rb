module Genesis
  module GitHandlers
    class Generic
      include Genesis::GitHandlers::Commons

      def initialize(info)
        @info = info
      end

      def name
        'Generic Git'
      end

      def has_services
        false
      end

      def validate_remote_url
        git_regex = /^git@([a-zA-Z\-]+(?<!\.git))\.git$/
        if git_regex.match(@info.remote.url).nil?
          Failure('Invalid remote url')
        else
          @info.remote.user_name = 'git'
          @info.remote.user_name = ask('Repository name? ') do |q|
            q.validate = /[A-Za-z0-9\-_\.]{2,}/
          end
        end
      end

      def git_create_remote
        git_push('master', true)
      end

    end
  end
end
