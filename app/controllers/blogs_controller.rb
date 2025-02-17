class BlogsController < ApplicationController
  def show
    slug = params.require(:slug)
    @blog = Blog.new(slug)
  rescue ArgumentError
    render file: "public/404.html", status: :not_found
  end
end
