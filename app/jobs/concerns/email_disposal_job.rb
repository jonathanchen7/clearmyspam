module EmailDisposalJob
  extend ActiveSupport::Concern

  included do
    include GoodJob::ActiveJobExtensions::Concurrency

    queue_as :default

    good_job_control_concurrency_with(
      key: -> { "#{arguments.find { |arg| arg.is_a?(User) }.id}:dispose" },
      perform_limit: 1,
      perform_throttle: [2, 2.seconds]
    )

    retry_on Google::Apis::RateLimitError, Google::Apis::ServerError,
             wait: ->(executions) { (executions * 2) + 15 + (rand(10) * (executions + 1)) },
             attempts: 10

    retry_on Google::Apis::ClientError,
             wait: ->(executions) { (executions * 2) + 15 + (rand(10) * (executions + 1)) },
             attempts: 3
  end
end
