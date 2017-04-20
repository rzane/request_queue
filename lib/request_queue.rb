require 'request_store'
require 'request_queue/version'
require 'request_queue/queue'
require 'request_queue/inline_queue'
require 'request_queue/fake_queue'
require 'request_queue/middleware'
require 'request_queue/railtie' if defined? Rails::Railtie

module RequestQueue
  BACKENDS = {
    inline: RequestQueue::InlineQueue,
    fake: RequestQueue::FakeQueue,
    default: RequestQueue::Queue
  }

  class MissingQueueError < StandardError
  end

  class << self
    def queue=(value)
      RequestStore.store[:request_queue] = value
    end

    def queue
      RequestStore.store[:request_queue]
    end

    def enqueue(message)
      if queue.nil?
        raise MissingQueueError, 'You need to wrap this call in RequestQueue.process {}'
      end

      queue << message
    end

    def process(backend = :default)
      restore do
        self.queue = BACKENDS.fetch(backend).new
        yield if block_given?
        queue.process
      end
    end

    private

    def restore
      original_queue = self.queue
      yield
    ensure
      self.queue = original_queue
    end
  end
end
