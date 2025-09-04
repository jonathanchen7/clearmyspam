module Debug
  class DeleteUserDataJob < ApplicationJob
    queue_as :default


    MODELS_TO_DELETE = [
      AccountPlan,
      Option,
      EmailTask,
      ProtectedEmail,
      ProtectedSender,
      Metrics
    ].freeze

    def perform(user)
      raise "Cannot delete user data for pro user #{user.email}." if user.account_plans.any? { |plan| AccountPlan::PRO_PLAN_TYPES.include?(plan.plan_type) }

      MODELS_TO_DELETE.each do |model|
        model.where(user: user).delete_all
      end

      user.destroy
    end
  end
end
