class OptionsController < AuthenticatedController
  set_rate_limit to: 20

  before_action :set_cached_inbox
  before_action :set_or_refresh_google_auth, if: -> { params.dig(:options, :unread_only).present? }

  def update
    sanitized_params = params.require(:options).permit(:archive, :hide_personal, :unread_only)

    Current.options.update(sanitized_params)

    if sanitized_params[:unread_only].present?
      reset_inbox
      inbox.cache!
    end

    respond_to do |format|
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

    if sanitized_params[:archive].present?
      stream << turbo_stream.replace("inbox_metrics", partial: "dashboard/inbox_metrics")
      stream << turbo_stream.replace("inbox_actions", Dashboard::InboxActionsComponent.new(inbox))
    end

    stream
  end
end
