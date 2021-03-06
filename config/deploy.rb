# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "audiobank"
set :scm, "git"
set :repository, "git://github.com/albanpeignier/audiobank.git"

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

role :app, "zigmun.tryphon.org"
role :web, "zigmun.tryphon.org"
role :db,  "zigmun.tryphon.org", :primary => true

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
# set :deploy_to, "/path/to/app" # defaults to "/u/apps/#{application}"
# set :user, "flippy"            # defaults to the currently logged in user
# set :scm, :darcs               # defaults to :subversion
# set :svn, "/path/to/svn"       # defaults to searching the PATH
# set :darcs, "/path/to/darcs"   # defaults to searching the PATH
# set :cvs, "/path/to/cvs"       # defaults to searching the PATH
# set :gateway, "gate.host.com"  # default to no gateway

set :keep_releases, 3
set :use_sudo, false

set :deploy_to, "/var/www/tryphon.org/audiobank/"

# =============================================================================
# SSH OPTIONS
# =============================================================================
# ssh_options[:keys] = %w(/path/to/my/key /path/to/another/key)

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

# Tasks may take advantage of several different helper methods to interact
# with the remote server(s). These are:
#
# * run(command, options={}, &block): execute the given command on all servers
#   associated with the current task, in parallel. The block, if given, should
#   accept three parameters: the communication channel, a symbol identifying the
#   type of stream (:err or :out), and the data. The block is invoked for all
#   output from the command, allowing you to inspect output and act
#   accordingly.
# * sudo(command, options={}, &block): same as run, but it executes the command
#   via sudo.
# * delete(path, options={}): deletes the given file or directory from all
#   associated servers. If :recursive => true is given in the options, the
#   delete uses "rm -rf" instead of "rm -f".
# * put(buffer, path, options={}): creates or overwrites a file at "path" on
#   all associated servers, populating it with the contents of "buffer". You
#   can specify :mode as an integer value, which will be used to set the mode
#   on the file.
# * render(template, options={}) or render(options={}): renders the given
#   template and returns a string. Alternatively, if the :template key is given,
#   it will be treated as the contents of the template to render. Any other keys
#   are treated as local variables, which are made available to the (ERb)
#   template.

# You can use "transaction" to indicate that if any of the tasks within it fail,
# all should be rolled back (for each task that specifies an on_rollback
# handler).

desc "Restart the web server"
task :restart do
  sudo "/etc/init.d/apache2 reload"
end

desc "Create media folder"
task :after_setup do
  run "mkdir #{shared_path}/cache"
	run "mkdir #{shared_path}/media"
	run "mkdir #{shared_path}/media/cue"
	run "mkdir #{shared_path}/media/cast"
	run "mkdir #{shared_path}/media/upload"
end

desc "Disable web before deployement"
task :before_deploy do
  disable_web
end

#desc "Migrate before restart"
#task :before_restart do
#  migrate
#end

desc "Put our own maintenance template"
task :disable_web do
  buffer = render("app/views/maintenance.rhtml", :deadline => ENV['UNTIL'], :reason => ENV['REASON'])
  put buffer, "#{shared_path}/system/maintenance.html", :mode => 0644
end

desc "Cleanup and enable web after deploy"
task :after_deploy do
  cleanup
  enable_web
end

desc "Add symlink"
task :after_symlink do
	run "ln -nfs #{shared_path}/system/mahoro.so #{release_path}/vendor/mahoro.so"
	run "ln -nfs #{shared_path}/media #{release_path}/media"
	run "ln -nfs #{shared_path}/cache #{release_path}/public/cache"
end
