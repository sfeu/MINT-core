require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require 'rdoc/task'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'MINT-core' do
  self.developer 'Sebastian Feuerstack', 'Sebastian@Feuerstack.org'
  self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  self.rubyforge_name       = self.name # TODO this is default value
#  self.extra_deps         = [['dm-redis-adapter','~> 0.1.2'],
#                             ['MINT-statemachine','~> 1.2.3'],
#                             ['MINT-scxml','~> 1.0.0'],
#                             ['cassowary','~> 1.0.1'],
#                             ["dm-core","~>1.2.0" ],
#                             ["cassowary","~>1.0.1"],
#                             ["eventmachine", "~>0.12.10"],
#                             ["rake","0.9.2.2"],
#                             ["rmagick","~>2.12.2"],
#                             ["json","~>1.5.1"],
#                             ["redis","~>2.2.1"],
#                             ["dm-types","~>1.2.0"],
#                             ["dm-serializer","~>1.2.0"]]
#  self.extra_dev_deps   =    [["rspec","1.3.1"],
#                              ["newgem","~>1.5.3"],
#                              [ "rdoc","~>3.11"]  ]


end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
