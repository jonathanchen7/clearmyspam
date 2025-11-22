# frozen_string_literal: true

class ErrorsController < ApplicationController
  def show
    @exception = request.env["action_dispatch.exception"]
    @status_code = @exception.try(:status_code) ||
                   ActionDispatch::ExceptionWrapper.new(request.env, @exception).status_code

    error_info = error_info_for_code(@status_code)
    @code = error_info[:code]
    @title = error_info[:title]
    @subheader = error_info[:subheader]

    render "error", status: @status_code
  end

  private

  def error_info_for_code(code)
    error_messages.fetch(code, error_messages[404])
  end

  def error_messages
    {
      403 => {
        code: "403",
        title: "Forbidden",
        subheader: "You don't have permission to access this resource."
      },
      404 => {
        code: "404",
        title: "Page not Found",
        subheader: "Sorry, we couldn't find the page you're looking for."
      },
      500 => {
        code: "500",
        title: "Sorry, something went wrong",
        subheader: "If you're the application owner, please check the logs for more details."
      }
    }
  end
end
