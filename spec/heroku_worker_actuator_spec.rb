require 'spec_helper'
require 'sidekiq_autoscaler/actuator/heroku_worker_actuator'

describe 'HerokuWorkerActuator' do
  before(:context) do
  end


  it 'should initialize with params' do
    SidekiqAutoscaler::Actuator::HerokuWorkerActuator.new({
      'SIDEKIQ_AUTOSCALER_APP_NAME' => 'not_empty',
      'SIDEKIQ_AUTOSCALER_HEROKU_API_KEY' => 'not_empty'
    })
  end
end

describe 'HerokuWorkerActuator Exceptions' do
  before(:context) do
  end

  it 'should fail on initialize without app_name' do
    expect {
      SidekiqAutoscaler::Actuator::HerokuWorkerActuator.new({
       'SIDEKIQ_AUTOSCALER_HEROKU_API_KEY' => 'not_empty'
      })
    }.to raise_error(StandardError)
  end

  it 'should fail on initialize without heroku_api_key' do
    expect {
      SidekiqAutoscaler::Actuator::HerokuWorkerActuator.new({
        'SIDEKIQ_AUTOSCALER_APP_NAME' => 'not_empty'
      })
    }.to raise_error(StandardError)
  end

end

