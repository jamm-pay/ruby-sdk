# frozen_string_literal: true

module Api
  class Customer
    # Allow to drill down to list charges.
    # e.g. cus.charges --> []
    def charges(pagination: nil)
      Jamm::Charge.list(
        customer: id,
        pagination: pagination
      )
    end
  end
end
