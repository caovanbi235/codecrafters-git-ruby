require 'digest/sha1'
require 'zlib'
# You can use print statements as follows for debugging, they'll be visible when running tests.
# puts "Logs from your program will appear here!"

# Uncomment this block to pass the first stage
#
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
  path = ".git/objects/#{object_hash[0,2]}/#{object_hash[2,38]}"
  cstr = File.read(path)
  store = Zlib::Inflate.inflate(cstr)
  header, content = store.split("\0")
  print content.strip
when "hash-object"
  file = ARGV[2]
  content = File.read(file)
  header = "blob #{content.length}\0"
  store = header + content
  sha1 = Digest::SHA1.hexdigest(store)
  zlib_content = Zlib::Deflate.deflate(store)
  path = ".git/objects/#{sha1[0,2]}/#{sha1[2,38]}"
  Dir.mkdir(File.dirname(path))
  File.open(path, "w") { |f| f.write(zlib_content) }
  print sha1
else
  raise RuntimeError.new("Unknown command #{command}")
end
