require "test_helper"

class PaymentWithdrawModeTest < ActiveSupport::TestCase
  def setup
    @payment_method = payment_methods(:paydunya)
    @order = orders(:one)
  end

  test "payment can have withdraw_mode" do
    payment = Payment.new(
      order: @order,
      payment_method: @payment_method,
      amount: 10000,
      status: :pending,
      withdraw_mode: "orange-money-senegal"
    )

    assert payment.valid?
    assert_equal "orange-money-senegal", payment.withdraw_mode
  end

  test "payment accepts all valid withdraw modes" do
    valid_modes = [
      "orange-money-senegal",
      "free-money-senegal",
      "expresso-senegal",
      "wave-senegal",
      "carte-bancaire"
    ]

    valid_modes.each do |mode|
      payment = Payment.new(
        order: @order,
        payment_method: @payment_method,
        amount: 10000,
        status: :pending,
        withdraw_mode: mode
      )

      assert payment.valid?, "Payment should be valid with withdraw_mode: #{mode}"
      assert_equal mode, payment.withdraw_mode
    end
  end

  test "payment can be created without withdraw_mode" do
    payment = Payment.new(
      order: @order,
      payment_method: @payment_method,
      amount: 10000,
      status: :pending
    )

    assert payment.valid?
    assert_nil payment.withdraw_mode
  end

  test "withdraw_mode is persisted to database" do
    payment = Payment.create!(
      order: @order,
      payment_method: @payment_method,
      amount: 10000,
      status: :pending,
      withdraw_mode: "wave-senegal"
    )

    payment.reload
    assert_equal "wave-senegal", payment.withdraw_mode
  end

  test "withdraw_mode can be updated" do
    payment = Payment.create!(
      order: @order,
      payment_method: @payment_method,
      amount: 10000,
      status: :pending,
      withdraw_mode: "orange-money-senegal"
    )

    payment.update!(withdraw_mode: "free-money-senegal")
    assert_equal "free-money-senegal", payment.withdraw_mode
  end

  test "payment has withdraw_mode column" do
    assert Payment.column_names.include?("withdraw_mode"),
           "Payment model should have withdraw_mode column"
  end

  test "withdraw_mode is string type" do
    column = Payment.columns_hash["withdraw_mode"]
    assert_equal :string, column.type, "withdraw_mode should be a string column"
  end
end
