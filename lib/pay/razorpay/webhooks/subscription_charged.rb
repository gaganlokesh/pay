module Pay
  module Razorpay
    module Webhooks
      class SubscriptionCharged
        def call(event)
          pay_customer = Pay::Customer.find_by(processor: :razorpay, processor_id: event.payload.subscription.entity.customer_id)

          # Find and update Pay::Customer with `processor_id` if it doesn't exist
          if pay_customer.nil?
            pay_subscription = Pay::Subscription.find_by(processor: :razorpay, processor_id: event.payload.subscription.entity.id)
            pay_customer = pay_subscription.customer
            pay_customer.update(processor_id: event.payload.subscription.entity.customer_id)
          end

          pay_charge = Pay::Razorpay::Charge.sync(event.payload.payment.entity.id)

          # Notify user
          notify_user(pay_charge)
        end

        private

        def notify_user(pay_charge)
          if Pay.send_email?(:receipt, pay_charge)
            Pay.mailer.with(pay_customer: pay_charge.customer, pay_charge: pay_charge).receipt.deliver_later
          end
        end
      end
    end
  end
end
