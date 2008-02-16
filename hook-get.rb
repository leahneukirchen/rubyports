#!/usr/bin/env ruby -w

class HookGet
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
end

ARGV.each { |file|
  HookGet.new.run(file)
}
