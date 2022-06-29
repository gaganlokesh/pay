module Pay
  module Razorpay
    class Charge
      attr_reader :pay_charge

      delegate :amount,
        :invoice_id,
        :processor_id,
        :processor_id?,
        to: :pay_charge

      def self.sync(charge_id, object: nil)
        object ||= ::Razorpay::Payment.fetch(charge_id)

        # Ignore charges without a Customer
        return if object.customer_id.blank?

        pay_customer = Pay::Customer.find_by(processor: :razorpay, processor_id: object.customer_id)
        return unless pay_customer

        attrs = {
          amount: object.amount,
          amount_refunded: object.amount_refunded,
          application_fee_amount: object.fee,
          bank: object.try(:bank),
          created_at: Time.zone.at(object.created_at),
          currency: object.currency,
          line_items: [],
          payment_method_type: object.method,
          razorpay_order_id: object.try(:order_id),
          tax: object.tax
        }

        # Include card details if payed with a card
        if object.method == "card" && object.try(:card_id).present?
          card_details = object.try(:card) || ::Razorpay::Payment.fetch_card_details(charge_id)
          attrs.merge!(
            brand: card_details.network,
            exp_month: card_details.try(:expiry_month),
            exp_year: card_details.try(:expiry_year),
            last4: card_details.last4
          )
        end

        # Include invoice details if available
        if object.try(:invoice_id).present?
          invoice = ::Razorpay::Invoice.fetch(object.invoice_id)

          attrs[:invoice_id] = invoice.id
          attrs[:period_start] = Time.zone.at(invoice.billing_start || invoice.created_at)
          attrs[:period_end] = Time.zone.at(invoice.billing_end || invoice.created_at)

          invoice.line_items.each do |line_item|
            line_item = OpenStruct.new(line_item)

            attrs[:line_items] << {
              id: line_item.id,
              item_id: line_item.item_id,
              amount: line_item.amount,
              description: line_item.description,
              name: line_item.name,
              unit_amount: line_item.unit_amount,
              quantity: line_item.quantity
            }
          end

          # Associate charge with subscription if we can
          attrs[:subscription] = pay_customer.subscriptions.find_by(processor_id: invoice.subscription_id)
        end

        # Update or create the charge
        if (pay_charge = pay_customer.charges.find_by(processor_id: object.id))
          pay_charge.with_lock do
            pay_charge.update!(attrs)
          end
          pay_charge
        else
          pay_customer.charges.create(attrs.merge(processor_id: object.id))
        end
      end

      def initialize(pay_charge)
        @pay_charge = pay_charge
      end

      def charge
        return unless processor_id?

        ::Razorpay::Payment.fetch(processor_id)
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      # Issue a refund for the charge
      # https://razorpay.com/docs/api/refunds
      #
      # refund!
      # refund!(1_00)
      # refund!(amount: 1_00)
      # refund!(1_00, speed: "optimum")
      def refund!(amount_to_refund = nil, **options)
        return unless processor_id?

        options[:amount] = amount_to_refund if amount_to_refund.present?
        ::Razorpay::Payment.fetch(processor_id).refund(options)

        amount_refunded = amount_to_refund.nil? ? amount : (pay_charge.amount_refunded + amount_to_refund)
        pay_charge.update(amount_refunded: amount_refunded)
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end

      def capture(**options)
        return unless processor_id?

        ::Razorpay::Payment.capture(processor_id, options)
      rescue ::Razorpay::Error => e
        raise Pay::Razorpay::Error, e
      end
    end
  end
end
