module Pay
  module Razorpay
    class Billable
      attr_reader :pay_customer

      delegate :processor_id,
        :processor_id?,
        to: :pay_customer

      def initialize(pay_customer)
        @pay_customer = pay_customer
      end

      def customer
        ::Razorpay::Customer.fetch(processor_id) if processor_id?
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error e
      end

      def update_customer!(**attributes)
        customer unless processor_id?
        ::Razorpay::Customer.edit(processor_id, attributes)
      end

      def charge(amount, options = {})
        # TODO: Implement
      end

      def subscribe(name: Pay.default_product_name, plan: Pay.default_plan_name, **options)
        trial_period_days = options.delete(:trial_period_days)
        start_at = options.delete(:start_at)
        opts = {plan_id: plan}.merge(options)

        opts[:start_at] = start_at if start_at

        # Set the start date to be in the future if a trial is being used
        if start_at.blank? && trial_period_days && trial_period_days > 0
          start_at = (Time.current + trial_period_days.days).to_i
          opts[:start_at] = start_at
        end

        # Create subscription in Razorpay
        rs = ::Razorpay::Subscription.create(opts)

        # Save Pay::Subscription
        trial_ends_at = Time.at(rs.start_at) if rs.start_at.present? && (rs.start_at > Time.current.to_i)
        ends_at = Time.at(rs.ended_at || rs.end_at) if rs.ended_at.present? || rs.end_at.present?
        pay_customer.subscriptions.create!(
          name: name,
          processor_id: rs.id,
          processor_plan: rs.plan_id,
          status: rs.status,
          quantity: rs.quantity,
          trial_ends_at: trial_ends_at,
          ends_at: ends_at
        )
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      def add_payment_method(payment_method_id, default: false)
        raise NotImplementedError, "Razorpay does not support adding payment methods"
      end

      def processor_subscription(subscription_id, options = {})
        ::Razorpay::Subscription.fetch(subscription_id)
      end

      def trial_end_date(subscription)
        subscription.start_at > Time.current.to_i ? Time.at(subscription.start_at) : nil
      end
    end
  end
end
