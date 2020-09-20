def clear_workers_queue
  Sidekiq::RetrySet.new.clear
  Sidekiq::ScheduledSet.new.clear
  Sidekiq::Stats.new.reset
  Sidekiq::DeadSet.new.clear

  Sidekiq::Queue.all.map(&:clear)
end