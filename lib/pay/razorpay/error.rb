module Pay
  module Razorpay
    class Error < Pay::Error
      delegate :message, to: :cause
    end
  end
end
