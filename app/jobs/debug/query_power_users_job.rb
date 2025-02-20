module Debug
  class QueryPowerUsersJob < ApplicationJob
    queue_as :default

    def perform(num_users: 5)
      User.joins(:email_threads)
          .where(email_threads: { trashed: true })
          .or(User.joins(:email_threads).where(email_threads: { archived: true }))
          .group(:id)
          .order(Arel.sql("COUNT(email_threads.id) DESC"))
          .limit(num_users)
    end
  end
end
