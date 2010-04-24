require 'java'
require 'jruby'

module GC
  import java.lang.management.ManagementFactory
  import java.lang.management.MemoryType
  GC_MBEANS = ManagementFactory.garbage_collector_mxbeans
  POOL_MBEANS = ManagementFactory.memory_pool_mxbeans
  
  # no perf penalty for stats on JVM, but save current counts
  def self.enable_stats
    @enabled = true
    @start_count = _collection_count
    @start_time = _collection_time
    @start_size = _total_pool_size
  end
  def self.disable_stats
    @enabled = false
  end
  
  # Number of GC runs since stat collection started.
  # This is accumulated across all GCs in the system.
  def self.collections
    raise "GC stats are not enabled" unless @enabled
    new_count = _collection_count
    new_count - @start_count
  end
  
  # Amount of time spent in GC since stat collection started
  # This is accumulated across all GCs in the system.
  def self.time
    raise "GC stats are not enabled" unless @enabled
    new_time = _collection_time
    new_time - @start_time
  end
  
  # Number of heap bytes requested since the last GC run.
  # This includes all memory pools.
  def self.growth
    _usage_versus_collected
  end
  
  # Dumping the basic data for each pool
  def self.dump
    filename = ENV['RUBY_GC_DATA_FILE']
    begin
      file = filename ? File.open(filename, 'w') : $stderr
      for pool_bean in POOL_MBEANS
        file.puts "Name: #{pool_bean.name}"
        file.puts "  Type: #{pool_bean.type}"
        file.puts "  Peak usage: #{pool_bean.peak_usage}"
        file.puts "  Current usage: #{pool_bean.usage}"
        file.puts "  Usage after last collection: #{pool_bean.collection_usage}"
        file.puts "  Managers: #{pool_bean.memory_manager_names.to_a.join(', ')}"
      end
    ensure
      file.close if filename
    end
  end
  
  # A delta in the committed (active main memory) size of all memory pools
  def self.allocation_size
    new_size = _total_pool_size
    new_size - @start_size
  end
  
  def self.num_allocations
    # not sure this can be tracked on JVM; allocations happen all over
  end
  
  private
  
  def self._collection_count
    GC_MBEANS.inject(0) {|tot, bean| tot + bean.collection_count}
  end
  
  def self._collection_time
    GC_MBEANS.inject(0) {|tot, bean| tot + bean.collection_time}
  end
  
  def self._usage_versus_collected
    POOL_MBEANS.inject(0) do |tot, bean|
      next tot if bean.type == MemoryType::NON_HEAP
      tot + (bean.usage.used - bean.collection_usage.used)
    end
  end
  
  def self._total_pool_size
    POOL_MBEANS.inject(0) do |tot, bean|
      tot + bean.usage.committed
    end
  end
end

module ObjectSpace
  def self.live_objects
    # not sure if there's a way to get this without tooling API on JVM
  end
  
  def self.allocated_objects
    # ditto
  end
end

class Object
  def caller_for_all_threads
    backtraces = {}
    ts = JRuby.runtime.thread_service
    ts.active_ruby_threads.each do |rthread|
      tc = ts.get_thread_context_for_thread(rthread)
      caller = tc.create_caller_backtrace(JRuby.runtime, 0)
      backtraces[rthread] = caller
    end
    backtraces
  end
end

if $0 == __FILE__
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
end