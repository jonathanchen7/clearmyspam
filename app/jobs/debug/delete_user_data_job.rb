module Debug
  class DeleteUserDataJob < ApplicationJob
    queue_as :default

    def perform(user, delete_account_plans: true, delete_options: true, delete_user: true)
      models_to_delete = {
        AccountPlan => delete_account_plans,
        Option => delete_options,
        User => delete_user
      }

      deleted_data = models_to_delete.each_with_object([]) do |(model, should_delete), data|
        if should_delete
          model == User ? user.destroy : model.where(user: user).delete_all
          data << model.name
        end
      end

      Rails.logger.warn "User #{user.id} data deleted: #{deleted_data.join(', ')}."
    end
  end
end
