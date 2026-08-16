require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @order = orders(:one)
    @payment_method = payment_methods(:paydunya)
    @payment = Payment.new(
      order: @order,
      payment_method: @payment_method,
      amount: 10000,
      status: :pending,
      user_id: @user.id,
      transaction_id: "TEST-#{SecureRandom.hex(8)}"
    )
  end

  test "should be valid with valid attributes" do
    assert @payment.valid?
  end

  test "should require order" do
    @payment.order = nil
    assert_not @payment.valid?
    assert_includes @payment.errors[:order], "must exist"
  end

  test "should require payment_method" do
    @payment.payment_method = nil
    assert_not @payment.valid?
    assert_includes @payment.errors[:payment_method], "must exist"
  end

  test "should require amount" do
    @payment.amount = nil
    assert_not @payment.valid?
    assert_includes @payment.errors[:amount], "can't be blank"
  end

  test "should require positive amount" do
    @payment.amount = -100
    assert_not @payment.valid?
    assert_includes @payment.errors[:amount], "must be greater than 0"
  end

  test "should require status" do
    @payment.status = nil
    assert_not @payment.valid?
  end

  test "should have valid status values" do
    valid_statuses = [ :pending, :processing, :completed, :failed, :refunded ]
    valid_statuses.each do |status|
      @payment.status = status
      assert @payment.valid?, "#{status} should be a valid status"
    end
  end

  test "should store paydunya token" do
    @payment.paydunya_token = "test_ABC123"
    assert @payment.save
    assert_equal "test_ABC123", @payment.paydunya_token
  end

  test "should store paydunya invoice url" do
    @payment.paydunya_invoice_url = "https://paydunya.com/invoice/test_ABC123"
    assert @payment.save
    assert_equal "https://paydunya.com/invoice/test_ABC123", @payment.paydunya_invoice_url
  end

  test "should store payment type" do
    @payment.payment_type = "PAR"
    assert @payment.save
    assert_equal "PAR", @payment.payment_type
  end

  test "should store provider response as json" do
    response = { response_code: "00", token: "test_123" }
    @payment.provider_response = response
    assert @payment.save
    assert_equal "00", @payment.provider_response["response_code"]
  end

  test "should check if completed" do
    @payment.status = :completed
    assert @payment.completed?

    @payment.status = :pending
    assert_not @payment.completed?
  end

  test "should check if pending" do
    @payment.status = :pending
    assert @payment.pending?

    @payment.status = :completed
    assert_not @payment.pending?
  end

  test "should check if failed" do
    @payment.status = :failed
    assert @payment.failed?

    @payment.status = :completed
    assert_not @payment.failed?
  end

  test "should set paid_at when marking as completed" do
    @payment.status = :completed
    @payment.paid_at = Time.current
    assert @payment.save
    assert_not_nil @payment.paid_at
  end
end
