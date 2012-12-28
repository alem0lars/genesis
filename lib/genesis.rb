require 'genesis/app'


module Genesis
  VERSION = [0, 1, 0]
  class << self
    def version
      VERSION.join('.')
    end
  end
end
