module Client::OrdersHelper
  def checkout_payment_options(cart_effective_payment_codes:, cart_cash_delivery_blocked:)
    active_methods = PaymentMethod.active.where(code: checkout_payment_visual_map.keys).index_by(&:code)
    options = []

    if !cart_cash_delivery_blocked && active_methods["cash_on_delivery"]
      options << checkout_payment_option_from("cash_on_delivery")
    end

    checkout_online_payment_method_codes.each do |method_code|
      payment_method = active_methods[method_code]
      next unless payment_method

      option = checkout_payment_option_from(method_code)
      next if cart_effective_payment_codes.is_a?(Array) && !cart_effective_payment_codes.include?(option[:value])

      options << option
    end

    options
  end

  def checkout_online_payment_method_codes
    %w[wave_sn orange_money_sn free_money_sn expresso_sn]
  end

  def checkout_payment_visual_map
    {
      "cash_on_delivery" => {
        value: "cash_on_delivery",
        label: "Payer à la livraison",
        description: "Payez à la livraison",
        icon: "payments/cash.png",
        payment_type: "cash"
      },
      "wave_sn" => {
        value: "wave-senegal",
        label: "Wave",
        icon: "payments/wave.png",
        payment_type: "online"
      },
      "orange_money_sn" => {
        value: "orange-money-senegal",
        label: "Orange Money",
        icon: "payments/om.png",
        payment_type: "online"
      },
      "free_money_sn" => {
        value: "free-money-senegal",
        label: "Free Money",
        icon: "payments/yas.png",
        payment_type: "online"
      },
      "expresso_sn" => {
        value: "expresso-senegal",
        label: "Expresso",
        icon: "payments/expresso.png",
        payment_type: "online"
      }
    }
  end

  def checkout_payment_option_from(method_code)
    map = checkout_payment_visual_map[method_code]
    {
      value: map[:value],
      label: map[:label],
      description: map[:description],
      icon: map[:icon],
      payment_type: map[:payment_type]
    }
  end
end
