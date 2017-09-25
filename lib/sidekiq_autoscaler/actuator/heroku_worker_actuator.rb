module SidekiqAutoscaler::Actuator
  require 'platform-api'
  require 'sidekiq'

  require 'sidekiq_autoscaler/util/sidekiq_util'

  class HerokuWorkerActuator
    include SidekiqAutoscaler
    include SidekiqAutoscaler::Util::Loggable

    KEY_APP_NAME = SidekiqAutoscaler::CONF_PREFIX+'APP_NAME'
    KEY_HEROKU_API_KEY = SidekiqAutoscaler::CONF_PREFIX+'HEROKU_API_KEY'
    KEY_MIN = SidekiqAutoscaler::CONF_PREFIX+'MIN'
    KEY_MAX = SidekiqAutoscaler::CONF_PREFIX+'MAX'

    @active = true

    @min_instances = nil
    @max_instances = nil

    @heroku_name = nil
    @heroku_api_key = nil

    @heroku = nil

    def initialize(options=ENV)
      @active = true
      self.log_prefix='HEROKU_WORKER_ACTUATOR: '

      @min_instances = (options[KEY_MIN] || '1').to_i
      @max_instances = (options[KEY_MAX] || '1').to_i

      @heroku_name = options[KEY_APP_NAME]
      if @heroku_name.blank?
        log(:error, "Invalid value for #{KEY_APP_NAME}. Actuator is disabled.")
        @active = false
      end

      @heroku_api_key = options[KEY_HEROKU_API_KEY]
      if @heroku_api_key.blank?
        log(:error, "Invalid value for #{KEY_HEROKU_API_KEY}. Actuator is disabled.")
        @active = false
      end

      begin
        if @active
          @heroku = PlatformAPI.connect_oauth(@heroku_api_key)
          @heroku.app.info(@heroku_name) #test connection
        end
      rescue => e
        log(:error, "Error initializing Heroku PlatformAPI: #{e}")
        @active = false
      end
    end

    public ################################################ PUBLIC #####################################################
    def active?
      @active
    end

    def stopped?
      instance_count == 0
    end

    def increase
      unless can_act?
        log(:debug, 'INCREASE ignored because of wait between actions')
        return false
      end

      instances = instance_count

      worker_data = Util::SidekiqUtil.worker_processes
      if worker_data.count != instances
        log(:warn, "Sidekiq and Heroku instances are not in sync. Ignoring.(#{worker_data.count}:#{instances})")
        return false
      end

      quiet_workers = worker_data.values.select{|w|w[:stopping]}
      unless quiet_workers.blank?
        quiet_empty_workers = quiet_workers.select{|w|w[:jobs].blank?}
        if quiet_empty_workers.blank?
          log("INCREASE: #{quiet_workers.count} workers are quiet but have jobs. Ignored...")
          return false
        end

        identity = quiet_empty_workers.first[:identity]
        Util::SidekiqUtil.stop_worker!(identity)
      end

      return false if instances >= @max_instances

      log('ADDING one worker')
      scale!(instances + 1)
      return true
    end

    def decrease(stop=false)
      unless can_act?
        log(:debug, 'DESCREASE ignored because of wait between actions')
        return false
      end

      instances = instance_count

      worker_data = Util::SidekiqUtil.worker_processes
      if worker_data.count != instances
        log(:warn, "Sidekiq and Heroku instances are not in sync. Ignoring.(#{worker_data.count}:#{instances})")
        return false
      end

      # Sidekiq actions should not apply to lonely process
      if worker_data.any?
        last_worker = worker_data.values.last
        if worker_data.count > 1
          unless last_worker[:stopping]
            Util::SidekiqUtil.quiet_worker!(last_worker[:identity])
            log('QUIET last worker!')
            return true
          end
        end

        unless last_worker[:jobs].blank?
          log('worker STILL HAS JOBS')
          return false
        end
      end

      #last worker should be quiet by now!

      if instances > [1, @min_instances].max
        log('REMOVING one worker')
        scale!(instances - 1)
        return true
      end

      if instances > [0, @min_instances].max && stop
        log('STOPPING workers')
        scale!(instances - 1)
        return true
      end

      return false
    end

    private ############################################### PRIVATE ####################################################
    @instance_cnt = nil
    @next_cnt = nil

    def instance_count
      @next_cnt ||= DateTime.now + 10.seconds
      return @instance_cnt if !@instance_cnt.nil? && @next_cnt > DateTime.now
      @next_cnt = nil

      data = @heroku.formation.list(@heroku_name)
      worker_data = data.find{|d|d['type'] == 'worker'}
      raise "HerokuWorkerActuator: Could not find formation data for 'worker':\n#{data}" if worker_data.blank?

      @instance_cnt = worker_data['quantity'].to_i
      return @instance_cnt
    end

    def scale!(quantity)
      @heroku.formation.update(@heroku_name, 'worker', {'quantity' => quantity})
    end

    @next_scale = nil
    def can_act?
      return false if !@next_scale.nil? && @next_scale > DateTime.now
      @next_scale = DateTime.now + 15.seconds
      return true
    end
  end #class
end #module
