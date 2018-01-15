require 'date'

def system_path
  @system_path ||= ENV["PATH"].split(":")
end

def osx_version
  @osx_version ||= %x(sw_vers -productVersion).split(".").slice(0, 2).join(".").chomp
end

def test_setup
  test_command_line_tools_setup
  test_sublime_setup
  test_path_setup
  test_homebrew_setup
  test_postgres_setup
  test_sqlite3_setup
  test_ruby_version_manager_setup
  test_ruby_setup
  test_gem_setup
end

def test_command_line_tools_setup
  test "Command Line Tools" do
    test_command_line_tools_installed
  end
end

def test_command_line_tools_installed
  case osx_version
  when "10.9"
    return true if ssystem("pkgutil --pkg-info=com.apple.pkg.CLTools_Executables")
  when "10.8"
    return true if ssystem("pkgutil --pkg-info=com.apple.pkg.DeveloperToolsCLI")
  else
    return true if ssystem("xcode-select -p")
  end

  error "OS X Command Line Tools are not installed. Install 'command line tools' for OS X #{osx_version}."
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
  ulb = system_path.index("/usr/local/bin")
  ub = system_path.index("/usr/bin")
  b = system_path.index("/bin")

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

def test_homebrew_updated
  # brew update does some fun stuff internally, so the local "stable" branch
  # doesn't have an upstream set. Instead it uses tags that match a particular
  # pattern. Here's the original source:
  # https://github.com/Homebrew/brew/blob/d4311fd49fe298513d71b269763f33e4f8069ba3/Library/Homebrew/cmd/update.sh#L220-L222
  tag_name = %x(cd $(brew --repository) &&
           git tag --list |
           sort --field-separator=. --key=1,1nr -k 2,2nr -k 3,3nr |
           grep --max-count=1 '^[0-9]*\.[0-9]*\.[0-9]*$')
  head, tag_head = %x(cd $(brew --repository) && git fetch &&
                      git rev-parse HEAD #{tag_name}).split("\n")
  return true if head == tag_head

  error "brew is outdated, run `brew update`"
end

def rbenv_present?
  ssystem("which rbenv")
end

def rvm_present?
  ssystem("which rvm")
end

def test_ruby_version_manager_setup
  if rbenv_present? && rvm_present?
    test "Ruby Version Manager" do
      error "both rvm and rbenv were found. Please uninstall one of them (e.g. rvm implode)."
      false
    end
  elsif rbenv_present?
    test_rbenv_setup
  elsif rvm_present?
    test_rvm_setup
  else
    test "Ruby Version Manager" do
      error "ruby version manager not found, install rbenv."
      false
    end
  end
end

def test_rbenv_setup
  test "Rbenv" do
    test_rbenv_dir_in_path &&
    test_rbenv_managing_ruby &&
    test_ruby_build_installed &&
    test_ruby_build_updated &&
    test_rbenv_default_gems &&
    test_rbenv_bundler_ruby_version
  end
end

def test_rbenv_dir_in_path
  return true if system_path.include?(File.join(%x(rbenv root).chomp, "shims"))

  error "rbenv shims not in path. Run `rbenv init` and follow the directions."
end

def test_rbenv_managing_ruby
  return true unless %x(rbenv version-name).chomp == "system"

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

def test_rbenv_default_gems
  return true if ssystem("ls -d $(rbenv root)/plugins/*/ | grep rbenv-default-gems")

  warn "rbenv-default-gems is not installed. Follow the directions here: https://github.com/rbenv/rbenv-default-gems. (optional)"
end

def test_rbenv_bundler_ruby_version
  return true if ssystem("ls -d $(rbenv root)/plugins/*/ | grep rbenv-bundler-ruby-version")

  warn "rbenv-bunlder-ruby-version is not installed. Follow the directions here: https://github.com/aripollak/rbenv-bundler-ruby-version. (optional)"
end

def test_rvm_setup
  test "RVM" do
    test_rvm_dir_in_path &&
    test_rvm_managing_ruby
  end
end

def test_rvm_dir_in_path
  return true if system_path.include?(File.expand_path("~/.rvm/bin"))

  error "rvm's bin is not in path."
end

def test_rvm_managing_ruby
  return true if %x(which ruby).index(File.expand_path("~/.rvm")) == 0

  error "rvm is not managing your ruby. Ensure that rvm is setup to use a version of ruby it is managing."
end

def test_postgres_setup
  test "Postgres" do
    test_postgres_installed &&
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
  return true if ssystem("brew outdated postgres")

  warn "postgres is outdated. Run `brew upgrade postgres`. (optional)"
end

def test_postgres_running
  postgres_process_found = ssystem("ps ax | grep postgres | grep -v grep")

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
  can_use_psql = ssystem('psql --list')

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
  trace_command_accessible = ssystem('sqlite3 /tmp/temp.db ".trace off"')

  return true if trace_command_accessible
  error "sqlite3 is not up to date. If Homebrew is ok, then `brew install sqlite3`."
end

def test_ruby_setup
  test "Ruby" do
    test_ruby_isnt_system &&
    test_ruby_version &&
    test_rubygems_location
  end
end

def test_ruby_isnt_system
  ruby_is_system = %x(which ruby).chomp == "/usr/bin/ruby"

  return true unless ruby_is_system

  error "ruby is not managed by a ruby version manager. Install rbenv, then run `rbenv install 2.2.0`."
end


RUBY_MIN_VERSION = "2.2.2"
def test_ruby_version
  required_ruby = RubyVersion.from_string(RUBY_MIN_VERSION)
  current_ruby = RubyVersion.from_string(%x(ruby -v | cut -d ' ' -f 2).chomp)

  return true if current_ruby >= required_ruby

  error "ruby is out of date (current running #{current_ruby}). Use your Ruby Version Manager to install #{required_ruby} or newer."
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

def gem_installed?(gem_name)
  @gem_list ||= %x(gem list -l --no-version).split("\n")
  @gem_list.include?(gem_name)
end

def test_gem_nokogiri
  return true if gem_installed?("nokogiri")

  error "nokogiri is not installed. If Ruby is ok, then run `gem install nokogiri`."
end

def test_gem_pg
  return true if gem_installed?("pg")

  error "pg is not installed. If Ruby and Postgres are ok, then run `gem install pg`."
end

def test_gem_sqlite3
  return true if gem_installed?("sqlite3")

  error "sqlite3 is not installed. If Ruby and SQLite3 are ok, then run `gem install sqlite3`."
end

def test_gem_rspec
  return true if gem_installed?("rspec")

  error "rspec is not installed. If Ruby and SQLite3 are ok, then run `gem install rspec`."
end

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

def ssystem(command)
  system("#{command} &>/dev/null")
end

class RubyVersion
  def initialize(major, minor = nil, teeny = nil, patch = nil)
    @major = major
    @minor = minor
    @teeny = teeny
    @patch = patch
  end

  def self.from_string(str)
    new(*str.split(/[.p]/).map(&:to_i))
  end

  def <=>(other)
    self.to_a <=> other.to_a
  end

  def >=(other)
    (self <=> other) >= 0
  end

  def to_a
    [@major, @minor || 0, @teeny || 0, @patch || 0]
  end

  def to_s
    version_string = "#{@major}"
    if @minor
      version_string << ".#{@minor}"
      if @teeny
        version_string << ".#{@teeny}"
        if @patch
          version_string << "p#{@patch}"
        end
      end
    end
    version_string
  end
end

test_setup
