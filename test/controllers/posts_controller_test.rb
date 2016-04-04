require 'test_helper'

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should create post" do
    assert_difference('Post.count') do
      post posts_url, params: { post: { comments_count: @post.comments_count, name: @post.name, namespace: @post.namespace, number: @post.number, revision_number: @post.revision_number, stargazers_count: @post.stargazers_count, url: @post.url, watchers_count: @post.watchers_count } }
    end

    assert_response 201
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should update post" do
    patch post_url(@post), params: { post: { comments_count: @post.comments_count, name: @post.name, namespace: @post.namespace, number: @post.number, revision_number: @post.revision_number, stargazers_count: @post.stargazers_count, url: @post.url, watchers_count: @post.watchers_count } }
    assert_response 200
  end

  test "should destroy post" do
    assert_difference('Post.count', -1) do
      delete post_url(@post)
    end

    assert_response 204
  end
end
