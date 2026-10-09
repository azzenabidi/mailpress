require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "index lists published posts and hides drafts" do
    get root_url

    assert_response :success
    assert_match "A published post", response.body
    assert_no_match "A draft post", response.body
  end

  test "index shows the newest post first" do
    get root_url

    assert_operator response.body.index("A published post"), :<, response.body.index("An older post")
  end

  test "show renders a published post by slug" do
    get post_url(posts(:published))

    assert_response :success
    assert_match "A published post", response.body
  end

  test "show is not found for drafts" do
    get post_url(posts(:draft))

    assert_response :not_found
  end

  test "rss feed exposes published posts only" do
    get posts_url(format: :rss)

    assert_response :success
    assert_match "A published post", response.body
    assert_no_match "A draft post", response.body
    assert_equal "application/rss+xml", response.media_type
  end
end
