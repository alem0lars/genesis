require 'rspec'


module TestMethods

end

RSpec.configure do |config|
  config.before(:each) do

  end

  config.include TestMethods
end
