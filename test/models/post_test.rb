require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "generates a slug from the title" do
    post = Post.create!(title: "Hello  World! Again")
    assert_equal "hello-world-again", post.slug
  end

  test "generates a unique slug when titles collide" do
    Post.create!(title: "Duplicate title")
    post = Post.create!(title: "Duplicate title")

    assert_equal "duplicate-title-2", post.slug
  end

  test "does not overwrite an explicit slug" do
    post = Post.create!(title: "Title", slug: "custom-slug")
    assert_equal "custom-slug", post.slug
  end

  test "requires a title" do
    post = Post.new(slug: "no-title")
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "the published scope only returns published posts newest first" do
    slugs = Post.published.pluck(:slug)
    assert_equal [ "a-published-post", "an-older-post" ], slugs
    assert_not_includes slugs, "a-draft-post"
  end

  test "publish! sets status and published_at" do
    post = posts(:draft)
    post.publish!

    assert post.published?
    assert_not_nil post.published_at
  end

  test "excerpt strips HTML and truncates" do
    post = Post.new(title: "x")
    post.content = "<p>Hello <strong>world</strong>, this is a fairly long body used for testing.</p>"

    assert_equal "Hello world, this is a fairly long body used for testing.", post.excerpt
    assert_operator post.excerpt(20).length, :<=, 21
  end

  test "to_param returns the slug" do
    assert_equal "a-published-post", posts(:published).to_param
  end
end
