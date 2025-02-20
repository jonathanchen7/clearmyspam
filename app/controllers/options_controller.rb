class OptionsController < AuthenticatedController
  rate_limit to: 20, within: 1.minute, by: -> { current_user.id }

  before_action :set_cached_inbox
  before_action :set_or_refresh_google_auth, if: -> { params.dig(:options, :unread_only).present? }

  def update
    sanitized_params = params.require(:options).permit(:archive_email_threads, :hide_personal_emails, :unread_only)

    Current.options.update(sanitized_params)

    if sanitized_params[:unread_only].present?
      with_rate_limit_rescue do
        reset_inbox
        inbox.cache!
      end

    end

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(sanitized_params)
      end
    end
  end

  private

  def build_turbo_stream(sanitized_params)
    stream = [
      turbo_stream.replace("options_dropdown", partial: "dashboard/options_dropdown"),
      turbo_stream.replace("senders_table", partial: "dashboard/senders_table")
    ]

    if sanitized_params[:unread_only].present?
      stream << turbo_stream.replace("load_more", partial: "dashboard/load_more")
    end

    if sanitized_params[:archive_email_threads].present?
      stream << turbo_stream.replace("inbox_metrics", partial: "dashboard/inbox_metrics")
      stream << turbo_stream.replace("inbox_actions", Dashboard::InboxActionsComponent.new(inbox))
    end

    stream
  end
end
