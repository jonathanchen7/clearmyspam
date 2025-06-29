module Gmail
  class SenderDisposer
    Result = Struct.new(:disposed_email_ids, :fully_disposed_sender_ids, :partially_disposed_senders)

    attr_reader :user, :senders, :result

    def initialize(user, senders)
      @user = user
      @senders = senders.uniq
      @result = Result.new(
        disposed_email_ids: [],
        fully_disposed_sender_ids: [],
        partially_disposed_senders: {}
      )
    end

    def dispose_all!
      senders.each do |sender|
        actionable_email_ids = sender.fetch_actionable_email_ids!(user)
        next if actionable_email_ids.blank?

        result.disposed_email_ids.concat(actionable_email_ids)

        if actionable_email_ids.count >= sender.email_count
          result.fully_disposed_sender_ids << sender.id
        else
          result.partially_disposed_senders[sender] = actionable_email_ids.count
        end
      end

      Email.dispose_all!(user, vendor_ids: result.disposed_email_ids)

      result
    end
  end
end
