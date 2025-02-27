class BlogsController < ApplicationController
  def show
    @blog = Blog.find_by_slug!(params[:slug])
  end

  def index
    @blogs = Blog.order(published_at: :desc)
  end
end
