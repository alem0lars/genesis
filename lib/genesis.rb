require 'rainbow'
require 'highline/import'
require 'awesome_print'
require 'genesis/shell_util'
require 'genesis/app'

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
