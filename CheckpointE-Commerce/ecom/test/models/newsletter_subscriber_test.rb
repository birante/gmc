require "test_helper"

class NewsletterSubscriberTest < ActiveSupport::TestCase
  test "should create newsletter subscriber with valid email" do
    subscriber = NewsletterSubscriber.new(email: "test@example.com")
    assert subscriber.valid?
    assert subscriber.save
  end

  test "should validate email presence" do
    subscriber = NewsletterSubscriber.new(email: "")
    assert_not subscriber.valid?
    assert subscriber.errors[:email].any?
  end

  test "should validate email format" do
    subscriber = NewsletterSubscriber.new(email: "invalid-email")
    assert_not subscriber.valid?
    assert subscriber.errors[:email].any?
  end

  test "should enforce email uniqueness" do
    NewsletterSubscriber.create!(email: "test@example.com")

    duplicate = NewsletterSubscriber.new(email: "test@example.com")
    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?
  end

  test "should downcase email before save" do
    subscriber = NewsletterSubscriber.create!(email: "TEST@EXAMPLE.COM")
    assert_equal "test@example.com", subscriber.email
  end

  test "should have subscribed scope" do
    create(:newsletter_subscriber, subscribed: true)
    create(:newsletter_subscriber, subscribed: false)

    assert_equal 1, NewsletterSubscriber.subscribed.count
  end

  test "should have unsubscribed scope" do
    create(:newsletter_subscriber, subscribed: true)
    create(:newsletter_subscriber, subscribed: false)

    assert_equal 1, NewsletterSubscriber.unsubscribed.count
  end
end
