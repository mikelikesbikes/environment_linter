require 'fileutils'
include FileUtils

require 'pry'

PATH = ENV["PATH"].split(":")

def test(string, &block)
  @errors = []
  @warnings = []

  result = block.call

  if result
    STDOUT.puts "[OK] #{string}"
  else
    STDERR.puts "[FAILED] #{string}"
  end

  print_errors
  print_warnings

  result
end

def print_errors
  @errors.each { |e| STDERR.puts "    [ERROR] #{e}" }
end

def print_warnings
  @warnings.each { |e| STDERR.puts "    [WARNING] #{e}" }
end

def error(string)
  @errors << string
  false
end

def warn(string)
  @warnings << string
  true
end

def test_setup
  test_sublime_setup
  test_path_setup
  test_homebrew_setup
  test_postgres_setup
  test_sqlite3_setup
  test_ruby_version_manager_setup
  test_ruby_setup
  test_gem_setup
end

def test_sublime_setup
  test "Sublime" do
    test_sublime_command &&
    test_sublime_version
  end
end

def test_sublime_command
  return true if ssystem("which subl")

  error "subl command is missing."
end

def test_sublime_version
  return true if %x(subl -v) =~ /\ASublime Text/

  error "subl set up incorrectly ('subl -v' failed to run)."
end

def test_path_setup
  test "Path" do
    test_path_ordering
  end
end

def test_path_ordering
  ulb = PATH.index("/usr/local/bin")
  ub = PATH.index("/usr/bin")
  b = PATH.index("/bin")

  return true if ulb < ub && ulb < b

  error"/usr/local/bin should come before both /usr/bin and /bin in $PATH"
end


def test_homebrew_setup
  test "Homebrew" do
    test_homebrew_command &&
    test_homebrew_updated
  end
end

def test_homebrew_command
  return true if ssystem("which brew")

  error "brew command is not reachable, install homebrew."
end

def ssystem(command)
  system("#{command} &>/dev/null")
end

def test_homebrew_updated
  cd %x(brew --repository).chomp
  head_fresh = Date.parse(%x(git show -s --format=%ci master)) == Date.today
  return true if head_fresh

  error "brew is outdated, run `brew update`"
end

def ruby_version_manager
  if ssystem("which rbenv")
    :rbenv
  elsif ssystem("which rvm")
    :rvm
  else
    nil
  end
end

def test_ruby_version_manager_setup
  case ruby_version_manager
  when :rbenv then return test_rbenv_setup
  when :rvm   then return test_rvm_setup
  end

  error "ruby version manager not found, install rbenv."
end

def test_rbenv_setup
  test "Rbenv" do
    test_rbenv_command &&
    test_rbenv_dir_in_path &&
    test_rbenv_managing_ruby &&
    test_ruby_build_installed &&
    test_ruby_build_updated
  end
end

def test_rbenv_command
  return true if ssystem("which rbenv")

  error "rbenv not found. Run `brew install rbenv`."
end

def test_rbenv_dir_in_path
  return true if PATH.include?(File.join(%x(rbenv root).chomp, "shims"))

  error "rbenv shims not in path. Run `rbenv init` and follow the directions."
end

def test_rbenv_managing_ruby
  return true unless %x(rbenv version-name) == "system"

  error "rbenv is not managing your ruby. Ensure ruby is installed by rbenv and set global ruby."
end

def test_ruby_build_installed
  return true if ssystem("which ruby-build") && ssystem("rbenv help install")

  error "ruby-build is not installed. Run `brew install ruby-build`."
end

def test_ruby_build_updated
  return true unless ssystem("brew outdated | grep ruby-build")

  error "ruby-build is out of date. Run `brew upgrade ruby-build`."
end

def test_rbenv_gem_rehash_installed
  return true if ssystem("brew list | grep rbenv-gem-rehash")

  warn "rbenv-gem-rehash is not installed. Run `brew install rbenv-gem-rehash`. (optional)"
end

def test_rvm
  test "RVM" do
    true
  end
end

def test_postgres_setup
  test "Postgres" do
    test_postgres_installed &&
    test_postgres_updated &&
    test_postgres_running &&
    test_postgres_autolauch_setup &&
    test_postgres_accessible
  end
end

def test_postgres_installed
  return true if ssystem("which psql") && ssystem("which postgres")

  error "postgres is not installed. Run `brew install postgres` and follow the instructions to launch postgres at login."
end

def test_postgres_updated
  return true unless ssystem("brew outdated postgres")

  warn "postgres is outdated. Run `brew upgrade postgres`. (optional)"
end

def test_postgres_running
  postgres_process_found = ssystem("ps ax | grep `brew --prefix postgres`")

  return true if postgres_process_found

  error "postgres is not running. Run `brew info postgres` and follow the instructions to launch postgres at login."
end

def test_postgres_autolauch_setup
  launch_agent_exists = ssystem("find $HOME/Library/LaunchAgents -name *postgres*")
  launchctl_loaded = ssystem("launchctl list | grep postgres")

  return true if launch_agent_exists && launchctl_loaded

  error "postgres is not setup to launch at login. Run `brew info postgres` and follow the instructions to launch postgres at login."
end

def test_postgres_accessible
  can_use_psql = ssystem('psql -c "\dt"')

  return true if can_use_psql

  error "psql is not accessible. Get help."
end

def test_sqlite3_setup
  test "SQLite3" do
    test_sqlite3_installed &&
    test_sqlite3_trace_available
  end
end

def test_sqlite3_installed
  return true if ssystem("which sqlite3")

  error "sqlite3 is not installed. Run `brew install sqlite3 && brew link sqlite3 --force --overwrite`"
end

def test_sqlite3_trace_available
  trace_command_accessible = ssystem('sqlite3 temp.db ".trace off"')

  return true if trace_command_accessible
  error "sqlite3 is not up to date. If Homebrew is ok, then `brew install sqlite3`."
end

def test_ruby_setup
  test "Ruby" do
    test_ruby_version &&
    test_rubygems_location
    # test that bundler is installed
  end
end

RUBY_VERSIONS = %w(2.0.0 2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.1.5 2.2.0)
def test_ruby_version
  ruby_version = %x(ruby -v | cut -d ' ' -f 2).split("p").first

  return true if RUBY_VERSIONS.include?(ruby_version)

  error "ruby is out of date (current running #{ruby_version}). Install rbenv, then run `rbenv install 2.2.0`."
end

def test_rubygems_location
  ruby_location = File.dirname(%x(which ruby))
  gem_location = File.dirname(%x(which gem))

  return true if ruby_location == gem_location

  error "ruby is not in the same location as rubygems. Get help."
end

def test_gem_setup
  test "Gems" do
    test_gem_bundler &&
    test_gem_nokogiri &&
    test_gem_pg &&
    test_gem_sqlite3 &&
    test_gem_rspec
  end
end

def test_gem_bundler
  test_gem_bundler_installed &&
  test_gem_bundle_command_location
end

def test_gem_bundler_installed
  return true if ssystem("which bundle")

  error "bundler is not installed. If Ruby is ok, then run `gem install bundler`."
end

def test_gem_bundle_command_location
  ruby_location = File.dirname(%x(which ruby))
  bundle_location = File.dirname(%x(which bundle))

  return true if ruby_location == bundle_location

  error "bundler is not installed in the correct location. If Ruby is ok, then run `gem install bundler`."
end

def test_gem_nokogiri
  return true if ssystem("gem list --no-version | grep nokogiri")

  error "nokogiri is not installed. If Ruby is ok, then run `gem install nokogiri`."
end

def test_gem_pg
  return true if ssystem("gem list --no-version | grep pg")

  error "pg is not installed. If Ruby and Postgres are ok, then run `gem install pg`."
end

def test_gem_sqlite3
  return true if ssystem("gem list --no-version | grep sqlite3")

  error "sqlite3 is not installed. If Ruby and SQLite3 are ok, then run `gem install sqlite3`."
end

def test_gem_rspec
  true
end

#test_rbenv_setup
test_setup
