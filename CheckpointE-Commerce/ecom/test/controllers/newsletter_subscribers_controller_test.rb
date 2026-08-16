require "test_helper"

class NewsletterSubscribersControllerTest < ActionDispatch::IntegrationTest
  test "should create newsletter subscriber with valid email" do
    assert_difference("NewsletterSubscriber.count") do
      post newsletter_subscribers_path, params: { email: "test@example.com" }, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_match(/inscription|merci/i, json["message"])
  end

  test "should reject invalid email" do
    assert_no_difference("NewsletterSubscriber.count") do
      post newsletter_subscribers_path, params: { email: "invalid-email" }, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "should not create duplicate email" do
    create(:newsletter_subscriber, email: "existing@example.com")

    assert_no_difference("NewsletterSubscriber.count") do
      post newsletter_subscribers_path, params: { email: "existing@example.com" }, as: :json
    end

    assert_response :success
  end

  test "should re-subscribe unsubscribed email" do
    subscriber = create(:newsletter_subscriber, email: "test@example.com", subscribed: false)

    assert_no_difference("NewsletterSubscriber.count") do
      post newsletter_subscribers_path, params: { email: "test@example.com" }, as: :json
    end

    assert_response :success
    subscriber.reload
    assert subscriber.subscribed?
  end
end
