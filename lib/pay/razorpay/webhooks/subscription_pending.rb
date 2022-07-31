module Pay
  module Razorpay
    module Webhooks
      class SubscriptionPending
        def call(event)
          pay_subscription = Pay::Subscription.find_by_processor_and_id(:razorpay, event.payload.subscription.entity.id)
          return unless pay_subscription.present?

          pay_subscription.update!(status: :past_due)
        end
      end
    end
  end
end
