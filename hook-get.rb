#!/usr/bin/env ruby -w

class HookGet
  def self.run(file)
    new.run(file)
  end

  def initialize
    @hooked_in = false
  end

  def run(file)
    instance_eval File.read(file), file, 1
    hookin  unless hooked_in?
  end

  def sh(*args)
    puts args.join(" ")
    system(*args)
  end

  def build(*args)
    Dir.chdir(pkgpath) { sh(*args) }
  end

  def darcs(repo, tag=nil)
    if tag
      sh "darcs", "get", "--partial", "--tag=#{tag}", pkgpath
    else
      sh "darcs", "get", "--partial", pkgpath
    end
  end

  def git(repo, head="HEAD")
    sh "git", "clone", "-n", repo, pkgpath
    sh "GIT_DIR=#{pkgpath} git checkout #{head}"
  end

  def svn(url)
    sh "svn", "co", "-q", url, pkgpath
  end

  def tar_gz(url)
    sh "curl -L #{url} | tar xz"
  end

  def tar_bz2(url)
    sh "curl -L #{url} | tar xj"
  end

  def gem(url)
    sh "mkdir -p #{pkgpath} && curl -L #{url} | tar xO data.tar.gz | tar xzm -C #{pkgpath}"
  end

  def package(name, version=nil)
    @pkgname = name
    @pkgversion = version
    @pkgpath = name + (version ? "-#{version}" : "")
  end

  attr_reader :pkgpath, :pkgversion, :pkgname
  def hooked_in?
    @hooked_in
  end

  def hookin(name=pkgpath, paths=[pkgpath + "/lib"])
    sh "hookin", "add", name, *paths
    @hooked_in = true
  end


  def depend(expr)
    installed = `hookin installed`.split
    package = expr[/^([\w-]*)(-[^-]*)?$/, 1]
    versions = installed.grep(/^#{package}(-[^-]*)?$/)

    chosen = choose_version(expr, versions)
    if chosen
      puts "dependency #{expr} satisfied: found #{chosen}"
    else
      available = Dir["#{package}*.rport"].
                  map { |f| File.basename f, ".rport" }.
                  grep(/^#{package}(-[^-]*)?$/)
      to_install = choose_version(expr, available)
      if to_install
        puts "hook-get #{to_install}  # satisfies #{expr}"
        HookGet.run "#{to_install}.rport"
      else
        abort "version conflict: unable to satisfy #{expr}"
      end
    end
  end

  def version2array(version)
    if version =~ /\d+(\.\d+)*$/
      $&.split('.').map { |f| f.to_i }
    else
      [1.0/0]                   # Infinity
    end
  end
  
  def choose_version(expr, available)
    min, max = expr.split("...", 2)
    max ||= min
    min = version2array min
    max = version2array max
    max[-1] += 1

    # just "pkg" means "any version"
    min = [-1.0/0]  if min == [1.0/0] && max == [1.0/0]

    available.select { |v| (min...max).include? version2array(v) }.
              sort_by { |v| version2array(v) }.
              last
  end
end

ARGV.each { |file|
  if File.file? file            # the sound of prisoners at night
    HookGet.run(file)
  else
    HookGet.new.depend(file)
  end
}
