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
  object_hash = ARGV[2]
  path = ".git/objects/#{object_hash[...2]}/#{object_hash[2..]}"
  store = Zlib::Inflate.inflate(File.read(path))
  header, content = store.split("\0")
  print content.strip
when "hash-object"
  content = File.read(ARGV[2])
  store = "blob #{content.length}\0#{content}"
  sha1 = Digest::SHA1.hexdigest(store)
  path = ".git/objects/#{sha1[...2]}/#{sha1[2..]}"
  Dir.mkdir(File.dirname(path))
  compress_content = Zlib::Deflate.deflate(store)
  File.open(path, "w") { |f| f.write(compress_content) }
  print sha1
else
  raise RuntimeError.new("Unknown command #{command}")
end
