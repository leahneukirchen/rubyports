#!/usr/bin/env ruby -w

require 'fileutils'

FileUtils.mkdir_p "bin"

Dir["*/bin/*"].each { |bin|
  FileUtils.ln_s File.expand_path(bin), "bin", :force => true, :verbose => true
}

FileUtils.ln_s File.expand_path("hook-bin.rb"), "bin/hook-bin",
  :force => true, :verbose => true
FileUtils.ln_s File.expand_path("hook-get.rb"), "bin/hook-get",
  :force => true, :verbose => true
