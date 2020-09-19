def clear_worker_queue
  Sidekiq::Queue.all.map(&:clear)
end