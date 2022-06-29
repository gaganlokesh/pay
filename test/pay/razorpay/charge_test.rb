require "test_helper"

class Pay::Razorpay::ChargeTest < ActiveSupport::TestCase
  setup do
    @pay_customer = pay_customers(:razorpay)
    @pay_charge = pay_charges(:razorpay)
  end

  test "sync creates Pay::Charge for razorpay payment" do
    assert_difference "Pay::Charge.count" do
      Pay::Razorpay::Charge.sync("pay_Jl1VbSwE6j2HF2")
    end
  end

  test "sync updates Pay::Charge for razorpay refunds" do
    @pay_charge.update(amount_refunded: 0)

    Pay::Razorpay::Charge.sync("pay_JkfXzlRImoMbpO")
    assert_equal 59800, @pay_charge.reload.amount_refunded
  end

  test "sync associates charge with razorpay subscription" do
    pay_subscription = pay_subscriptions(:razorpay)
    pay_charge = Pay::Razorpay::Charge.sync("pay_JkfXzlRImoMbpO")
    assert_equal pay_subscription, pay_charge.subscription
  end

  test "sync records razorpay invoice ID" do
    pay_charge = Pay::Razorpay::Charge.sync("pay_JkfXzlRImoMbpO")
    assert_equal "inv_JkfTtPSFsEI6Cb", pay_charge.invoice_id
  end

  test "sync records razorpay card details for charge" do
    pay_charge = Pay::Razorpay::Charge.sync("pay_JkfXzlRImoMbpO")
    assert_equal "MasterCard", pay_charge.brand
    assert_equal "5449", pay_charge.last4
  end

  test "razorpay can get razorpay charge" do
    razorpay_charge = @pay_charge.processor_charge
    assert_equal @pay_charge.processor_id, razorpay_charge.id
  end

  test "razorpay can refund a charge" do
    pay_charge = @pay_customer.charges.create!(
      processor_id: "pay_Jl17fxsI08Db5o",
      amount: 1_00,
      amount_refunded: 0
    )
    pay_charge.refund!
    pay_charge.reload
    assert_equal pay_charge.amount, pay_charge.amount_refunded
    assert_equal pay_charge.amount, pay_charge.processor_charge.amount_refunded
  end

  test "razorpay can refund a charge with a partial amount" do
    @pay_charge.update(
      processor_id: "pay_Jl1VbSwE6j2HF2",
      amount: 2396_00,
      amount_refunded: 0
    )
    @pay_charge.refund!(10_00)
    assert_equal 10_00, @pay_charge.reload.amount_refunded
    assert_equal 10_00, @pay_charge.processor_charge.amount_refunded
  end
end
