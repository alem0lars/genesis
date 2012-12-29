require 'git_handlers/commons'

require 'git_handlers/generic'
require 'git_handlers/github'


# The available git handlers
AVAIL_GIT_HANDLERS = [
    Genesis::GitHandlers::Generic,
    Genesis::GitHandlers::Github
]
