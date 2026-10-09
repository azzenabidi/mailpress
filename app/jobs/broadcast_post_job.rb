class BroadcastPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return if post.nil? || !post.published?

    Turbo::StreamsChannel.broadcast_remove_to "posts", target: "empty-state"
    Turbo::StreamsChannel.broadcast_prepend_to "posts",
      target: "posts",
      partial: "posts/post",
      locals: { post: post }
  end
end
