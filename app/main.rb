require 'digest/sha1'
require 'zlib'
require 'fileutils'
require 'time'

def compress_and_write_file(type, file)
  origin = "#{type} #{file.length}\0#{file}"
  compressed_content = Zlib::Deflate.deflate(origin)
  sha1 = Digest::SHA1.hexdigest(origin)
  path = ".git/objects/#{sha1[...2]}/#{sha1[2..]}"
  FileUtils.mkdir_p(File.dirname(path))
  File.open(path, "w") { |f| f.write(compressed_content) }
  sha1
end

def uncompress_from_sha1(sha1)
  path = ".git/objects/#{sha1[...2]}/#{sha1[2..]}"
  uncompressed_content = Zlib::Inflate.inflate(File.read(path))
  header, content = uncompressed_content.split(/\0/, 2)
  content
end

def write_tree_object(dir)
  tree_entries = ""
  dir_children = Dir.children(dir).sort
  dir_children.each do |f|
    next if f.start_with?(".") && FileTest.directory?(f)

    path = "#{dir}/#{f}"
    if FileTest.directory?(path)
      binaries = [write_tree_object(path)].pack("H*")
      tree_entries << "40000 #{File.basename(path)}\0#{binaries}"
    elsif FileTest.file?(path)
      binaries = [write_blob_object(path)].pack("H*")
      tree_entries << "100644 #{File.basename(path)}\0#{binaries}"
    end
  end
  compress_and_write_file("tree", tree_entries) 
end

def write_blob_object(f)
  compress_and_write_file("blob", File.read(f)) 
end

command = ARGV[0]
case command
when "init"
  FileUtils.mkdir_p(".git")
  FileUtils.mkdir_p(".git/objects")
  FileUtils.mkdir_p(".git/refs")
  File.write(".git/HEAD", "ref: refs/heads/master\n")
  puts "Initialized git directory"
when "cat-file"
  print uncompress_from_sha1(ARGV[2])
when "hash-object"
  puts write_blob_object(ARGV[2])
when "ls-tree"
  contents = uncompress_from_sha1(ARGV[2])
  contents = contents.split(" ")[1..]
  results = []
  contents.each do |content|
    result = content.split(/\0/).first
    results << result if result && result.ascii_only?
  end
  puts results.sort
when "write-tree"
  puts write_tree_object(Dir.pwd)
when "commit-tree"
  tree_sha, _p, commit_sha, _m, message = ARGV[1..]
  current_time = Time.now.to_i
  commit_object = "tree #{tree_sha}\n"
  commit_object << "parent #{commit_sha}\n" if commit_sha
  commit_object << "author Cao Van Bi <caovanbi235@gmail.com> #{current_time} +0900\n"
  commit_object << "commiter Cao Van Bi <caovanbi235@gmail.com> #{current_time} +0900\n"
  commit_object << "\n#{message}\n"
  puts compress_and_write_file("commit", commit_object)
when "clone"
  url, dir = ARGV[1..]
  puts url, dir
else
  raise RuntimeError.new("Unknown command #{command}")
end
