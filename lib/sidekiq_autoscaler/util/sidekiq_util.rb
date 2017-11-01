module SidekiqAutoscaler::Util
  class SidekiqUtil
    require 'sidekiq/api'

    def self.workers
      return Sidekiq::Workers.new
    end

    def self.process_set
      Sidekiq::ProcessSet.new
    end

    def self.stats
      Sidekiq::Stats.new
    end

    def self.current_jid
      return Thread.current.object_id.to_s(36)
    end

    def self.current_worker(jid = nil)
      jid ||= self.current_jid

      self.workers.each {|process_id, thread_id, work|
        payload = work['payload'] || {}
        return build_job_data(process_id, thread_id, work) if payload['jid'] == jid
      }

      return nil
    end

    def self.running_jobs
      return self.workers.map{|process_id, thread_id, work| build_job_data(process_id, thread_id, work)}
    end

    def self.worker_jobs(pid)
      jobs = self.workers.select{|process_id, thread_id, work| process_id == pid}
      return jobs.map{|process_id, thread_id, work| build_job_data(process_id, thread_id, work)}
    end

    def self.worker_processes
      worker_names = self.process_set.map {|p| [p.send(:identity), p.stopping?]}
      sorted_workers = worker_names.sort_by {|d| d[0].match(/worker\.(\d+)/)[1].to_i} # sort by worker index

      worker_data = {}
      sorted_workers.each {|identity, stopping|
        worker_data[identity] = {
            identity: identity,
            stopping: stopping,
            jobs: self.worker_jobs(identity)}
      }
      return worker_data
    end

    def self.queue_size(queue = nil)
      queue_arr = queue.nil? ? Sidekiq::Queue.all : [Sidekiq::Queue.new(queue)]
      return queue_arr.map(&:size).sum
    end

    def self.retry_count(before = nil)
      Sidekiq::RetrySet.new.select{|r| before.nil? || r.enqueued_at < before}.count
    end

    def self.scheduled_count(before = nil)
      Sidekiq::ScheduledSet.new.select{|r| before.nil? || r.enqueued_at < before}.count
    end

    def self.max_latency
      return Sidekiq::Queue.all.map(&:latency).max
    end

    def self.quiet_worker!(identity)
      get_worker(identity).quiet!
    end

    def self.stop_worker!(identity)
      get_worker(identity).stop!
    end

    def self.get_worker(identity)
      process = self.process_set.find{|p|p.send(:identity) == identity}
      return process
    end

    private
    def self.build_job_data(process_id, thread_id, work)
      # work: {
      #     "queue" => "default",
      #     "payload" => {
      #         "class" => "ReportWorker",
      #         "args" => [25543, "https://provas.studiare.com.br/master_users/run_daily_reports?locale=pt-BR"],
      #         "retry" => false,
      #         "queue" => "default",
      #         "jid" => "03d5d52ca14530c8de7048df",
      #         "created_at" => 1504710487.2551432,
      #         "enqueued_at" => 1504710492.5349371
      #   },
      #   "run_at" => 1504710492
      # }

      payload = work['payload'] || {}
      return {
          class: payload['class'],
          args: payload['args'], #array
          queue: payload['queue'],
          jid: payload['jid'],
          thread_id: thread_id,
          process_id: process_id
      }
    end
  end #class
end #module
