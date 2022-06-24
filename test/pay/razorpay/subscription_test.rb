require "test_helper"

class Pay::Razorpay::SubscriptionTest < ActiveSupport::TestCase
  setup do
    @pay_customer = pay_customers(:razorpay)
  end

  test "sync Pay::Customer after subscription activation" do
    pay_customer = pay_customers(:pending_razorpay)
    pay_subscription = pay_customer.subscription
    Pay::Razorpay::Subscription.sync(pay_subscription.processor_id, object: fake_razorpay_subscription)
    pay_customer.reload
    assert_equal pay_customer.processor_id, fake_razorpay_subscription.customer_id
  end

  test "razorpay change quantity" do
    pay_subscription = @pay_customer.subscription
    pay_subscription.change_quantity(5)
    assert_equal 5, pay_subscription.processor_subscription.quantity
  end

  test "razorpay cancel" do
    pay_subscription = @pay_customer.subscription
    pay_subscription.cancel
    assert_equal pay_subscription.ends_at.to_date, Time.zone.at(pay_subscription.processor_subscription.current_end).to_date
    assert_equal "canceled", pay_subscription.status
  end

  test "razorpay cancel immediatly" do
    pay_subscription = @pay_customer.subscribe(name: "starter", plan: "plan_JjkGtEmLF2ujkn", total_count: 10)
    pay_subscription.cancel_now!
    assert_not_nil pay_subscription.processor_subscription.ended_at
    assert pay_subscription.ends_at <= Time.current
    assert_equal "canceled", pay_subscription.status
  end

  test "razorpay can swap plans" do
    pay_subscription = @pay_customer.subscription
    pay_subscription.swap("plan_JjkGtEmLF2ujkn")
    Pay::Razorpay::Subscription.sync(pay_subscription.processor_id)
    assert_equal "plan_JjkGtEmLF2ujkn", pay_subscription.processor_plan
    assert_equal "active", pay_subscription.status
  end

  test "razorpay pause" do
    pay_subscription = @pay_customer.subscription
    pay_subscription.pause
    pay_subscription = Pay::Razorpay::Subscription.sync(pay_subscription.processor_id)
    assert_equal "paused", pay_subscription.status
  end

  test "razorpay resume on paused state" do
    pay_subscription = @pay_customer.subscription
    pay_subscription.pause
    pay_subscription = Pay::Razorpay::Subscription.sync(pay_subscription.processor_id)
    assert_equal "paused", pay_subscription.status

    pay_subscription.resume
    pay_subscription = Pay::Razorpay::Subscription.sync(pay_subscription.processor_id)
    assert_equal "active", pay_subscription.status
  end

  private

  def fake_razorpay_subscription
    object = {
      id: "sub_Jl363MsPi27RHB",
      entity: "subscription",
      plan_id: "plan_JSO9sX3CbJy73r",
      customer_id: "cust_JjnE2x6g6hAayY",
      status: "active",
      current_start: 1656012034,
      current_end: 1658601000,
      ended_at: nil,
      quantity: 1,
      notes: [],
      charge_at: 1658601000,
      start_at: 1656012034,
      end_at: 1916418600,
      auth_attempts: 0,
      total_count: 100,
      paid_count: 1,
      customer_notify: true,
      created_at: 1656011938,
      expire_by: nil,
      short_url: nil,
      has_scheduled_changes: false,
      change_scheduled_at: nil,
      source: "dashboard",
      payment_method: "card",
      offer_id: nil,
      remaining_count: 99
    }

    OpenStruct.new(object)
  end
end
