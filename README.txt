Title: jruby-gc-stats

Description:

This is a set of GC-monitoring methods for JRuby that mimic behavior of Ruby
Enterprise Edition's GC methods. In our case, these are all implemented in
Ruby, using the JVM's built-in monitoring and management APIs.

Example Usage:

require 'jruby/gc_stats'

require 'pp'
puts "Enabling stats..."
GC.enable_stats
puts "allocation size: #{GC.allocation_size}"
puts "Running loop..."
1_000.times {
  ary = []
  1_000.times {ary << 'foo' + 'bar'}
}
puts "collections: #{GC.collections}"
puts "time: #{GC.time}ms"
puts "bytes since last GC: #{GC.growth}"
puts "size change: #{GC.allocation_size}"
puts "Dumping..."
GC.dump

puts "Dumping caller for all threads..."
2.times {Thread.new {sleep}}
pp caller_for_all_threads