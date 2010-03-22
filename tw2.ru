require 'tw2'

use Rack::CommonLogger

map "/push/tw.rb" do
  run TwitterPush.new
end
