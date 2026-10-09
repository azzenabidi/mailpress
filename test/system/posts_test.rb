require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  test "the index lists published posts and hides drafts" do
    visit root_path

    assert_text "A published post"
    assert_text "An older post"
    assert_no_text "A draft post"
  end

  test "a post page renders its permalink" do
    visit post_path(posts(:published))

    assert_text "A published post"
    assert_current_path post_path(posts(:published))
  end
end
