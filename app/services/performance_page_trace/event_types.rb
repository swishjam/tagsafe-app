module PerformancePageTrace
  class EventTypes
    class << self
      %i[
        DURATION 
        COMPLETE 
        INSTANT 
        COUNTER 
        ASYNC 
        FLOW 
        SAMPLE 
        OBJECT 
        METADATA 
        MEMORY_DUMP
        MARK 
        CLOCK_SYNC 
        CONTEXT
      ].each{ |type| define_method(type){ type } }

      def DICTIONARY
        {
          DURATION: ['B', 'E'],
          COMPLETE: ['X'],
          INSTANT: ['i'],
          COUNTER: ['C'],
          ASYNC: ['b', 'n', 'e'],
          FLOW: ['s', 't', 'f'],
          SAMPLE: ['P'],
          OBJECT: ['N', 'O', 'D'],
          METADATA: ['R'],
          MEMORY_DUMP: ['V', 'v'],
          MARK: ['R'],
          CLOCK_SYNC: ['c'],
          CONTEXT: ['(', ')']
        }
      end
    end
  end
end