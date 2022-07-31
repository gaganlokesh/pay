module Pay
  module Razorpay
    module Webhooks
      class SubscriptionUpdated
        def call(event)
          Pay::Razorpay::Subscription.sync(event.payload.subscription.entity.id)
        end
      end
    end
  end
end
