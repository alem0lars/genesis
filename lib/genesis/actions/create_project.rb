require 'fileutils'


module Genesis
  module Actions

    class CreateProject
      include Genesis::Actions::BasicAction

      def on_register
        { :name => :create_project }
      end

      def execute
        ask_for_project
        status = ask_for_repo

        if status
          FileUtils.makedirs @prj_pth, :verbose => true
        end

        if status && @with_git
          cmds = ['git init', 'touch .gitignore', 'git add -A',
              'git commit -m "init"', "git remote add origin #@remote_repo"]
          if @remote_repo_exists
            cmds << 'git pull origin master'
          end
          Dir.chdir(@prj_pth) do
             status = cmds.each_exec
          end
        end

        if status && @with_git && @using_github
          status = github_services
        end

        status
      end

      private

      # Ask to the user for the project informations
      # It sets:
      # * @prj_name to the project name provided by the user
      # * @prj_base_dir to the directory that hosts the project
      def ask_for_project
        @prj_name = ask('Project name? ') do |q|
          q.validate = /[A-Za-z0-9\-\.@]{2,}/
        end

        @prj_base_dir = Pathname.new(ask('Project base directory? ') do |q|
          q.default = '/usr/local/archive/projects'
        end)

        @prj_pth = @prj_base_dir.join(@prj_name)
      end

      # Ask to the user for the repository informations
      # It sets:
      # * @with_git to true if the user wants to use git (currently its the only
      #           repository supported)
      # * @using_github to true if the remote repository is a github repository
      # * @user_name to the remote git user name
      # * @repo_name to the repository name
      # * @remote_repo to the remote repository url
      # * @remote_repo_exists to true if the remote repository already exists
      def ask_for_repo
        github_nothing_regex = /^github$/
        github_no_prj_regex = /^github:(?<username>[a-zA-Z0-9\-]+)$/
        github_regex = /^github:(?<un>[a-zA-Z0-9\-]+)\/(?<rn>[a-zA-Z0-9\-\.]+)$/
        git_regex = /^git@([a-zA-Z\-]+(?<!\.git))\.git$/

        @with_git = agree('Use git? ')
        @using_github = false
        @user_name, @repo_name = nil, nil
        @remote_repo, @remote_repo_exists = nil, nil

        if @with_git
          @remote_repo = ask('Remote repository? (github or github:USER_NAME '\
              'or github:USER_NAME:REPO_NAME or git@URL.git)')

          md = github_nothing_regex.match(@remote_repo)
          unless md.nil?
            @using_github = true
            @user_name, @repo_name = ENV['USER'], @prj_name
          end

          if @user_name.nil? || @repo_name.nil?
            md = github_no_prj_regex.match(@remote_repo)
            unless md.nil?
              @using_github = true
              @user_name, @repo_name = md[:un], @prj_name
            end
          end

          if @user_name.nil? || @repo_name.nil?
            md = github_regex.match(@remote_repo)
            unless md.nil?
              @using_github = true
              @user_name = md[:un]
              @repo_name = md[:rn]
            end
          end

          if @user_name.nil? || @repo_name.nil?
            md = git_regex.match(@remote_repo)
            unless md.nil?
              @user_name, @repo_name = 'git', ask('Repository name? ')
            end
          end

          if @using_github
            repo_str = @repo_name.end_with?('.git') ? @repo_name :
                "#@repo_name.git"
            @remote_repo = "git@github.com:#@user_name/#{repo_str}"
          end

          if @user_name && @repo_name && @remote_repo
            @remote_repo_exists = agree('Remote repository already exists? ')
          else
            unless @opts.quiet
              error_str = 'Invalid remote repository'
              puts(@opts.colors ? error_str.color(:red) : error_str)
            end
          end
        end

        (@user_name && @repo_name && @remote_repo) || !@with_git
      end

      # Ask to the user for additional github-only services
      # It sets:
      # * @using_gh_pages to true if the user wants the project website under
      #                 github pages
      # * @prj_website_base_pth to the path that hosts the local copy
      #                       of the repository for the project website
      # * @prj_website_pth to the path that contains the project website
      #
      # Based on the user input it can:
      # * Setup the remote repository
      # * Setup the github pages
      def github_services
        status = true

        unless @remote_repo_exists
          if ask('Remote repository doesn\'t exist. Create it? ')
            Dir.chdir(@prj_pth) do
              status = [
                "curl -u '#@user_name' https://api.github.com/user/repos"\
                    " -d '{\"name\":\"#@repo_name\"}'",
                'git push origin master'
              ].each_exec
            end
            @remote_repo_exists = status
          end
        end

        if status
          @using_gh_pages = agree('Do you want the project website? ')
          if @using_gh_pages
            @prj_website_base_pth = Pathname.new(
                ask('Project website base directory? ') do |q|
              q.default = '/usr/local/archive/projects/projects-websites'
            end)
            @prj_website_pth = @prj_website_base_pth.join(@prj_name)
            FileUtils.makedirs @prj_website_pth, :verbose => true

            gh_pages_exists = agree('The project website remotely exists? ')

            cmds = if gh_pages_exists
              [ 'git init',
                "git remote add -t gh-pages -f origin "\
                    "git@github.com:#@user_name/#@repo_name.git",
                'git checkout gh-pages',
                'git pull origin gh-pages'
               ]
            else
              [ 'git init',
                "git remote add origin "\
                    "git@github.com:#@user_name/#@repo_name.git",
                'git symbolic-ref HEAD refs/heads/gh-pages',
                'touch index.html',
                'git add -A', 'git commit -m "init"',
                'git push -u origin gh-pages'
              ]
            end
            Dir.chdir(@prj_website_pth) do
              status = cmds.each_exec
            end
          else
            @prj_website_pth = nil
          end
        end

        status
      end
    end

  end
end
