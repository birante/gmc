require "test_helper"

class SubscriptionPaymentTest < ActiveSupport::TestCase
  setup do
    @shop = create(:shop)
    @plan = Plan.find_by(code: "STARTER") || create(:plan, code: "STARTER", price: 50000)
    @payment_method = PaymentMethod.find_by(code: "paydunya") || create(:payment_method, code: "paydunya", is_active: true)
  end

  test "should create subscription payment" do
    subscription_payment = @shop.subscription_payments.build(
      plan: @plan,
      payment_method: @payment_method,
      amount: 50000,
      status: "pending",
      withdraw_mode: "wave-senegal"
    )

    assert_difference("SubscriptionPayment.count", 1) do
      subscription_payment.save!
    end

    assert_equal "pending", subscription_payment.status
    assert subscription_payment.transaction_id.present?
    assert subscription_payment.transaction_id.start_with?("SUB-TXN-")
  end

  test "should validate presence of required fields" do
    subscription_payment = @shop.subscription_payments.build(
      plan: nil,
      payment_method: @payment_method,
      amount: 50000,
      status: "pending",
      withdraw_mode: "wave-senegal"
    )

    assert_not subscription_payment.valid?
    assert subscription_payment.errors[:plan].any?
  end

  test "should validate amount is positive" do
    subscription_payment = @shop.subscription_payments.build(
      plan: @plan,
      payment_method: @payment_method,
      amount: 0,
      status: "pending",
      withdraw_mode: "wave-senegal"
    )

    assert_not subscription_payment.valid?
    assert subscription_payment.errors[:amount].any?
  end

  test "should have correct status transitions" do
    subscription_payment = create(:subscription_payment, shop: @shop, plan: @plan, payment_method: @payment_method, withdraw_mode: "wave-senegal")

    subscription_payment.reload
    assert_equal "pending", subscription_payment.status
    assert subscription_payment.pending?
    assert_not subscription_payment.completed?

    subscription_payment.update(status: "completed", paid_at: Time.current)
    assert subscription_payment.completed?
  end
end
