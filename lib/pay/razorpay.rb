module Pay
  module Razorpay
    autoload :Billable, "pay/razorpay/billable"
    autoload :Charge, "pay/razorpay/charge"
    autoload :Error, "pay/razorpay/error"
    autoload :Subscription, "pay/razorpay/subscription"

    module Webhooks
      autoload :RefundProcessed, "pay/razorpay/webhooks/refund_processed"
      autoload :SubscriptionActivated, "pay/razorpay/webhooks/subscription_activated"
      autoload :SubscriptionCharged, "pay/razorpay/webhooks/subscription_charged"
      autoload :SubscriptionCompleted, "pay/razorpay/webhooks/subscription_completed"
      autoload :SubscriptionUpdated, "pay/razorpay/webhooks/subscription_updated"
      autoload :SubscriptionPending, "pay/razorpay/webhooks/subscription_pending"
      autoload :SubscriptionHalted, "pay/razorpay/webhooks/subscription_halted"
      autoload :SubscriptionPaused, "pay/razorpay/webhooks/subscription_paused"
      autoload :SubscriptionResumed, "pay/razorpay/webhooks/subscription_resumed"
    end

    extend Env

    def self.enabled?
      return false unless Pay.enabled_processors.include?(:razorpay) && defined?(::Razorpay)

      Pay::Engine.version_matches?(required: "~> 3", current: ::Razorpay::VERSION) || (raise "[Pay] razorpay gem must be version ~> 3")
    end

    def self.setup
      ::Razorpay.setup(key_id, key_secret)
    end

    def self.key_id
      find_value_by_name(:razorpay, :key_id)
    end

    def self.key_secret
      find_value_by_name(:razorpay, :key_secret)
    end

    def self.signing_secret
      find_value_by_name(:razorpay, :signing_secret)
    end

    def self.configure_webhooks
      Pay::Webhooks.configure do |events|
        events.subscribe "razorpay.refund.processed", Pay::Razorpay::Webhooks::RefundProcessed.new
        events.subscribe "razorpay.subscription.activated", Pay::Razorpay::Webhooks::SubscriptionActivated.new
        events.subscribe "razorpay.subscription.charged", Pay::Razorpay::Webhooks::SubscriptionCharged.new
        events.subscribe "razorpay.subscription.completed", Pay::Razorpay::Webhooks::SubscriptionCompleted.new
        events.subscribe "razorpay.subscription.updated", Pay::Razorpay::Webhooks::SubscriptionUpdated.new
        events.subscribe "razorpay.subscription.pending", Pay::Razorpay::Webhooks::SubscriptionPending.new
        events.subscribe "razorpay.subscription.halted", Pay::Razorpay::Webhooks::SubscriptionHalted.new
        events.subscribe "razorpay.subscription.paused", Pay::Razorpay::Webhooks::SubscriptionPaused.new
        events.subscribe "razorpay.subscription.resumed", Pay::Razorpay::Webhooks::SubscriptionResumed.new
      end
    end
  end
end
