module Pay
  module Webhooks
    class RazorpayController < Pay::ApplicationController
      if Rails.application.config.action_controller.default_protect_from_forgery
        skip_before_action :verify_authenticity_token
      end

      def create
        queue_event(verified_event)
        head :ok
      rescue SecurityError => e
        logger.error e.message
        head :bad_request
      end

      private

      def queue_event(event)
        return unless Pay::Webhooks.delegator.listening?("razorpay.#{event["event"]}")

        record = Pay::Webhook.create!(processor: :razorpay, event_type: event["event"], event: event)
        Pay::Webhooks::ProcessJob.perform_later(record)
      end

      def verified_event
        payload = request.body.read
        signature = request.headers["X-Razorpay-Signature"]
        ::Razorpay::Utility.verify_webhook_signature(payload, signature, secret)

        JSON.parse(payload)
      end

      def secret
        secret = Pay::Razorpay.signing_secret
        return secret if secret
        raise SecurityError.new("Cannot verify signature without a Razorpay signing secret")
      end
    end
  end
end
