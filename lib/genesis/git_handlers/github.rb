module Genesis
  module GitHandlers
    class Github
      include Genesis::GitHandlers::Commons

      def initialize(info)
        @info = info
      end

      def name
        'Github'
      end

      def validate_remote_url
        regex_empty = /^github$/
        regex_no_prj = /^github:(?<user_name>[a-zA-Z0-9\-]+)$/
        regex_full = /^github:(?<user_name>[a-zA-Z0-9\-]+)\/(?<repo_name>[a-zA-Z0-9\-\.]+)$/

        Either.chain do
          bind -> { # Try to match regex_empty
            if regex_empty.match(@info.remote.url).nil?
              @info.remote.user_name = ENV['USER']
              @info.remote.repo_name = @info.prj_name
            else
              true
            end
          }
          bind ->(matched) { # Try to match regex_no_prj
            if (md = regex_no_prj.match(@info.remote.url)).nil? || matched
              true
            else
              @info.remote.user_name = md[:user_name]
              @info.remote.repo_name = @info.prj_name
            end
          }
          bind ->(matched) { # Try to match regex_full
            if matched
              true
            elsif (md = regex_full.match(@info.remote.url)).nil?
              false
            else
              @info.remote.user_name = md[:user_name]
              @info.remote.repo_name = md[:repo_name]
            end
          }
          bind -> { # Here we got a match, now format correctly the remote url
            @info.remote.url = "git@github.com:#{@info.remote.user_name}/"
            @info.remote.url << @info.remote.repo_name.end_with?('.git') ?
                @info.remote.repo_name : "#{@info.remote.repo_name}.git"
          }
        end

      end

      def git_create_remote
        Dir.chdir(@info.prj_pth) do
          Either.chain do
            bind -> {
              RestClient.post('https://api.github.com/user/repos',
                  {:params => {:name => @info.remote.repo_name}})
            }
            bind -> { git_push('master', true) }
          end
        end
      end

      def has_services
        true
      end

      def ls_services
        'GithubPages'
      end

      def use_services
        Either.chain do
          bind -> { setup_gh_pages_service }
        end
      end

      private

      def setup_gh_pages_service
        if agree('Do you want the project website? ')
          Either.chain do
            bind -> {
              ghp_base_dir_pth = ask('Project website base directory? ') do |q|
                q.default = '/usr/local/archive/projects/projects-websites'
              end
              @info.gh.pages.base_dir_pth = Pathname.new(ghp_base_dir_pth)
              @info.gh.pages.pth = @info.gh.pages.base_dir_pth.join(@info.prj_name)

              FileUtils.makedirs @info.gh.pages.pth, :verbose => true

              if agree('The project website remotely exists? ')
                setup_gh_pages_from_local
              else
                setup_gh_pages_from_remote
              end
            }
            bind -> { @info.gh.pages.remote_exists = true }
          end
        else
          true
        end
      end

      def setup_gh_pages_from_local
        Either.chain do
          bind -> { git_init(@info.gh.pages.pth) }
          bind -> {
            git_add_remote_url(@info.gh.pages.pth, "git@github.com:"\
                "#{@info.remote.user_name}/#{@info.remote.repo_name}.git")
          }
          bind -> {
            Dir.chdir(@info.gh.pages.pth) do
              execute 'git symbolic-ref HEAD refs/heads/gh-pages'
            end
          }
          bind -> { create_gitignore }
          bind -> { git_commit('Github Pages init', @info.gh.pages.pth) }
          bind -> { git_push('gh-pages', true, @info.gh.pages.pth) }
        end
      end

      def setup_gh_pages_from_remote
        Either.chain do
          bind -> { git_init(@info.gh.pages.pth) }
          bind -> {
            Dir.chdir(@info.gh.pages.pth) do
              "git remote add -t gh-pages -f origin #{@info.remote.url}"
            end
          }
          bind -> { git_checkout('gh-pages', false, @info.gh.pages.pth) }
          bind -> { git_pull('gh-pages', @info.gh.pages.pth) }
        end
      end

    end
  end
end
