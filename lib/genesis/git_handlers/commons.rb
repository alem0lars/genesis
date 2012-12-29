module Genesis
  module GitHandlers
    module Commons
      include Genesis::ShellUtil

      def git_add_remote
        Either.chain do
          bind -> { @info.remote.url = ask('Remote repository? ') }
          bind -> { # Remote url validation
            status = validate_remote_url
            status.success? ? status : Failure('Remote repository is invalid') }
          bind -> {
            @info.remote.exists = agree('Remote repository already exists? ')
            true
          }
          bind -> { git_add_remote_url }
        end
      end

      def git_sync_with_remote
        if @info.remote.exists?
          Either.chain do
            bind -> { git_pull }
            bind -> { git_push }
          end
        else
          Either.chain do
            bind -> { create_gitignore }
            bind -> { git_commit('Init of .gitignore') }
            bind -> { git_create_remote }
            bind -> { git_push }
          end
        end
      end

      def git_init(pth = @info.prj_pth)
        Dir.chdir(pth) do
          execute 'git init'
        end
      end

      def git_commit(msg = 'No commit message', pth = @info.prj_pth)
        Dir.chdir(pth) do
          Either.chain do
            bind -> { 'git add -A' }
            bind -> { "git commit -a -m \"#{msg}\"" }
          end
        end
      end

      def git_checkout(branch = 'master', create = false, pth = @info.prj_pth)
        opts = []
        opts.push('-b') if create
        cmd = 'git checkout '
        cmd.push(" #{opts.join(' ')}") unless opts.empty?
        Dir.chdir(pth) { execute "#{cmd} #{branch}" }
      end

      def git_add_remote_url(url = @info.remote.url, pth = @info.prj_pth)
        Dir.chdir(pth) do
          execute "git remote add origin #{url}"
        end
      end

      def git_pull(branch = 'master', pth = @info.prj_pth)
        Dir.chdir(pth) do
          execute "git pull origin #{branch}"
        end
      end

      def git_push(branch = 'master', add_upstream = false, pth = @info.prj_pth)
        opts = []
        opts.push('-u') if add_upstream
        cmd = 'git push'
        cmd.push(" #{opts.join(' ')}") unless opts.empty?
        Dir.chdir(pth) { execute "#{cmd} origin #{branch}" }
      end

      def create_gitignore(pth = @info.prj_pth)
        with_template = agree('Do you want a .gitignore from a template? ')
        gitignore_content = with_template ? get_gitignore_from_template : ''

        Dir.chdir(pth) do
          File.open('.gitignore', 'w') { |f| f.write(gitignore_content) }
        end
      end

      def get_gitignore_from_template
        specific = JSON.parse(RestClient.get(
            'https://api.github.com/repos/github/gitignore/contents',
            :accept => :json))
        global = JSON.parse(RestClient.get(
            'https://api.github.com/repos/github/gitignore/contents/Global',
            :accept => :json))
        all = global.zip(specific).flatten.compact.uniq # all avail gitignore
        all = all.select { |e| e['path'] != 'Global' }
        all_names = all.collect{ |e| e['path'].sub('.gitignore', '') }
        all_names_str = "[ #{all_names.join(', ')} ]"

        chosen = ask("these are the available gitignores:\n#{all_names_str}\n"\
            "Choose the ones you want (the chosen will be merge)..")
        chosen = chosen.sub(/\s*\[\s*/, '')
        chosen = chosen.sub(/\s*\]\s*/, '')
        chosen = chosen.split(/\s*,\s*/)

        gitignore_content = ''
        chosen.each do |name|
          gitignore_content << RestClient.get("https://raw.github.com"\
              "/github/gitignore/master/#{name}.gitignore")
        end
        gitignore_content
      end
    end
  end
end
