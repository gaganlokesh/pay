require "test_helper"

class Pay::Razorpay::BillableTest < ActiveSupport::TestCase
  setup do
    @user = users(:razorpay)
    @pay_customer = @user.payment_processor
  end

  test "razorpay can create a subscription" do
    pay_subscription = @pay_customer.subscribe(name: "starter", plan: "plan_JjkGtEmLF2ujkn", total_count: 10)
    assert_equal "starter", pay_subscription.name
    assert_equal "created", pay_subscription.status
    assert_equal "plan_JjkGtEmLF2ujkn", pay_subscription.processor_plan
  end

  test "razorpay can create a subscription with trial" do
    pay_subscription = @pay_customer.subscribe(
      name: "starter",
      plan: "plan_JjkGtEmLF2ujkn",
      total_count: 10,
      trial_period_days: 7
    )
    assert_not_nil pay_subscription.trial_ends_at
    assert_equal 7, Time.zone.at(pay_subscription.processor_subscription.start_at).to_date - Time.current.to_date
  end

  test "razorpay fails when subscribing without total_count" do
    exception = assert_raises(Pay::Razorpay::Error) do
      @pay_customer.subscribe(name: "starter", plan: "plan_JjkGtEmLF2ujkn")
    end
    assert_equal "The total count field is required when end at is not present.", exception.message
  end
end
