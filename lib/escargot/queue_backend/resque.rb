module Escargot
  module QueueBackend
    class Rescue < Base
      def enqueue(classname, *arguments)
        Resque.enqueue(classname, *arguments)
      end
    end
  end
end