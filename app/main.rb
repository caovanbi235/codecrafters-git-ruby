require 'digest/sha1'
require 'zlib'
# You can use print statements as follows for debugging, they'll be visible when running tests.
# puts "Logs from your program will appear here!"

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
  decompress_content = Zlib::Inflate.inflate(File.read(path))
  header, content = decompress_content.split(/\0/)
  print content.strip
when "hash-object"
  file = ARGV[2]
  content = File.read(file)
  store = "blob #{content.length}\0#{content}"
  sha1 = Digest::SHA1.hexdigest(store)
  path = ".git/objects/#{sha1[...2]}/#{sha1[2..]}"
  Dir.mkdir(File.dirname(path))
  compress_content = Zlib::Deflate.deflate(store)
  File.open(path, "w") { |f| f.write(compress_content) }
  print sha1
when "ls-tree"
  tree_sha = ARGV[2]
  path = ".git/objects/#{tree_sha[...2]}/#{tree_sha[2..]}"
  decompress_content = Zlib::Inflate.inflate(File.read(path)) 
  header, contents = decompress_content.split(/\0/, 2)
  contents = contents.split(/\s/)[1..]

  results = []
  contents.each do |content|
    result = content.split(/\0/).first
    results << result if result.ascii_only?
  end
  puts results.sort
else
  raise RuntimeError.new("Unknown command #{command}")
end
