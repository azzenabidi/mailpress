class PostsController < ApplicationController
  PAGE_SIZE = 10

  def index
    page = params[:page].to_i.clamp(1..)

    scope = Post.published.offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE + 1)
    @posts = scope.to_a
    @next_page = page + 1 if @posts.size > PAGE_SIZE
    @posts = @posts.first(PAGE_SIZE)

    respond_to do |format|
      format.html
      format.rss
    end
  end

  def show
    @post = Post.published.find_by!(slug: params[:id])
  end
end
