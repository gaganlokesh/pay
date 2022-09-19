module Pay
  module Razorpay
    class Subscription
      attr_reader :pay_subscription

      delegate :canceled?,
        :ends_at,
        :on_trial?,
        :owner,
        :processor_subscription,
        :processor_id,
        :processor_plan,
        :trial_ends_at,
        :quantity?,
        :quantity,
        to: :pay_subscription

      def self.sync(subscription_id, object: nil, name: nil)
        object ||= ::Razorpay::Subscription.fetch(subscription_id)

        pay_customer = Pay::Customer.find_by(processor: :razorpay, processor_id: object.customer_id)
        pay_subscription = Pay::Subscription.find_by(processor_id: object.id)
        return unless pay_subscription

        # If the Pay::Customer with `processor_id` cannot be found, then we need to find it by
        # the subscription and then update the processor_id
        if pay_customer.nil?
          pay_customer = pay_subscription.customer
          pay_customer.update(processor_id: object.customer_id)
        end
        return unless pay_customer

        attributes = {
          processor_plan: object.plan_id,
          quantity: object.quantity
        }

        # Standardize status
        attributes[:status] = case object.status
        when "created"
          :incomplete
        when "authenticated"
          :trialing
        when "pending"
          :past_due
        when "halted"
          :unpaid
        when "cancelled"
          :canceled
        when "expired"
          :incomplete_expired
        else
          object.status
        end

        # Razorpay supports trial for subscriptions by setting the start date to a future date.
        # We can check the `start_at` value to determine if the subscription is on trial or not.
        if object.start_at && object.start_at > Time.current.to_i
          attributes[:trial_ends_at] = Time.at(object.ended_at || object.start_at)
        end

        if object.ended_at
          attributes[:ends_at] = Time.at(object.ended_at)
        end

        # Update the subscription
        pay_subscription.with_lock { pay_subscription.update!(attributes) }
        pay_subscription
      end

      def initialize(pay_subscription)
        @pay_subscription = pay_subscription
      end

      def subscription(**options)
        ::Razorpay::Subscription.fetch(processor_id)
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      def cancel(**options)
        if on_trial?
          ::Razorpay::Subscription.cancel(processor_id)
          pay_subscription.update(ends_at: trial_ends_at, status: :canceled)
        else
          rs = ::Razorpay::Subscription.cancel(processor_id, {cancel_at_cycle_end: 1})
          pay_subscription.update(ends_at: Time.at(rs.current_end))
        end
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      def cancel_now!(**options)
        ::Razorpay::Subscription.cancel(processor_id)
        pay_subscription.update(ends_at: Time.current, status: :canceled)
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      def on_grace_period?
        canceled? && Time.current < ends_at
      end

      def active?
        pay_subscription.status == "active"
      end

      def paused?
        pay_subscription.status == "paused"
      end

      def pause
        unless active?
          raise StandardError, "You can only pause active subscriptions."
        end

        ::Razorpay::Subscription.pause(processor_id, {pause_at: "now"})
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      def resume
        unless paused?
          raise StandardError, "You can only resume paused subscriptions."
        end

        ::Razorpay::Subscription.resume(processor_id, {resume_at: "now"})
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      def swap(plan)
        raise ArgumentError, "plan must be a string" unless plan.is_a?(String)

        ::Razorpay::Subscription.fetch(processor_id).edit({plan_id: plan})
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      def change_quantity(quantity)
        ::Razorpay::Subscription.fetch(processor_id).edit({quantity: quantity})
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end
    end
  end
end
