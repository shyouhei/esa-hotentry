class PostsController < ApplicationController
  # GET /posts
  def index
    render text: Post.to_md
  end
end
