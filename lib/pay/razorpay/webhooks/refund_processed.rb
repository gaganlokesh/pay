module Pay
  module Razorpay
    module Webhooks
      class RefundProcessed
        def call(event)
          pay_charge = Pay::Charge.find_by_processor_and_id(:razorpay, event.payload.refund.entity.payment_id)
          return unless pay_charge

          pay_charge.update!(amount_refunded: event.payload.payment.entity.amount_refunded)

          # Notify user
          notify_user(pay_charge)
        end

        private

        def notify_user(pay_charge)
          if Pay.send_email?(:refund, pay_charge)
            Pay.mailer.with(pay_customer: pay_charge.customer, pay_charge: pay_charge).refund.deliver_later
          end
        end
      end
    end
  end
end
