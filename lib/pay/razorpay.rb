module Pay
  module Razorpay
    autoload :Billable, "pay/razorpay/billable"
    autoload :Charge, "pay/razorpay/charge"
    autoload :Error, "pay/razorpay/error"
    autoload :Subscription, "pay/razorpay/subscription"

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
  end
end
