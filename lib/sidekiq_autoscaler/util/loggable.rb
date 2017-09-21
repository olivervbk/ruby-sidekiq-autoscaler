module SidekiqAutoscaler::Util::Loggable
  attr_accessor :log_prefix

  @logger = nil
  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def logger=(logger)
    @logger = logger
  end

  def log(level=:info, message)
    logger.send(level, "#{log_prefix}#{message}")
  end
end
