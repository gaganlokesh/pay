module Pay
  module Razorpay
    module Webhooks
      class SubscriptionActivated
        def call(event)
          Pay::Razorpay::Subscription.sync(event.payload.subscription.entity.id)
        end
      end
    end
  end
end
