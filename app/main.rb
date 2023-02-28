require 'digest/sha1'
require 'zlib'
require 'fileutils'

def compresse_and_write_file(type, file)
  origin = "#{type} #{file.length}\0#{file}"
  compressed_content = Zlib::Deflate.deflate(origin)
  sha1 = Digest::SHA1.hexdigest(origin)
  path = ".git/objects/#{sha1[...2]}/#{sha1[2..]}"
  FileUtils.mkdir_p(File.dirname(path))
  File.open(path, "w") { |f| f.write(compressed_content) }
  sha1
end

def write_tree_object(dir)
  tree_entries = ""
  dir_children = Dir.children(dir).sort
  dir_children.each do |f|
    next if f.start_with?(".")
    #p f
    path = "#{dir}/#{f}"
    if FileTest.directory?(path)
      binaries = [write_tree_object(path)].pack("H*")
      tree_entries << "40000 #{File.basename(path)}\0#{binaries}"
    elsif FileTest.file?(path)
      binaries = [write_blob_object(path)].pack("H*")
      tree_entries << "100644 #{File.basename(path)}\0#{binaries}"
    end
  end
  compresse_and_write_file("tree", tree_entries) 
end

def write_blob_object(f)
  compresse_and_write_file("blob", File.read(f)) 
end

command = ARGV[0]
case command
when "init"
  Dir.mkdir(".git")
  Dir.mkdir(".git/objects")
  Dir.mkdir(".git/refs")
  File.write(".git/HEAD", "ref: refs/heads/master\n")
  puts "Initialized git directory"
when "cat-file"
  blob_sha = ARGV[2]
  path = ".git/objects/#{blob_sha[...2]}/#{blob_sha[2..]}"
  uncompressed_content = Zlib::Inflate.inflate(File.read(path))
  header, content = uncompressed_content.split(/\0/)
  print content.strip
when "hash-object"
  print write_blob_object(ARGV[2])
when "ls-tree"
  tree_sha = ARGV[2]
  path = ".git/objects/#{tree_sha[...2]}/#{tree_sha[2..]}"
  uncompressed_content = Zlib::Inflate.inflate(File.read(path)) 
  header, contents = uncompressed_content.split(/\0/, 2)
  contents = contents.split(" ")[1..]

  results = []
  contents.each do |content|
    result = content.split(/\0/).first
    results << result if result && result.ascii_only?
  end
  puts results.sort
when "write-tree"
  print write_tree_object(Dir.pwd).split(/\0/).last
else
  raise RuntimeError.new("Unknown command #{command}")
end
