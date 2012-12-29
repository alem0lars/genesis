require 'rainbow'
require 'highline/import'
require 'awesome_print'
require 'monadic'
require 'json'
require 'rest_client'

require 'genesis/shell_util'
require 'genesis/app'
require 'genesis/git_handlers'
require 'genesis/actions'


module Genesis
  VERSION = [0, 1, 0]
  class << self
    def version
      VERSION.join('.')
    end
  end
end

AVAIL_ACTIONS = [Genesis::Actions::CreateProject.new]
