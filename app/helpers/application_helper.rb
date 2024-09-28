module ApplicationHelper
  def currency_convert(in_usd, price)
    if in_usd
      number_to_currency(price)
    else
      num_to_usd(price)
    end
  end

  def translit(text)
    return '' if text.nil?

    Translit.convert(text, :english)
  end

  def clink_to(title, link, image_name, method = :get)
    styled_image = raw("<i class=\"bi #{image_name}\"></i>")
    if method == :get
      link_to link, title: title, method: method do
        styled_image
      end
    else
      button_to link, title: title, method: method, data: { confirm: strip_tags('вы уверены?') } do
        styled_image
      end
    end
  end

  def cdlink_to(title, link, icon = "bi-x-circle", confirm_text = "вы уверены?")
    button_to link, title: title, style: 'color: blue; cursor: pointer; border: none; background: none', method: :delete, data: { confirm: strip_tags(confirm_text) } do
      content_tag(:i, '', class: %i[bi fa-fw].push(icon))
    end
  end

  def active_check(active)
    style = active ? "green" : "red"
    status_class = active ? "true fa-check" : "false bi-x"
    "<i style=\"color: #{style}\" class=\"fa fa-fw active-check-#{status_class}\"></i>".html_safe
  end

  def num_to_usd(price)
    number_to_currency(price, unit: "")
  end

  def find_user_part_day(day, user)
    return "error" if user.nil?

    status =
      user.participations
        .where("DATE(created_at) = ?", day)
    result = ""
    if status.exists?
      case status.last.status
      when "пришёл"
        result = "<i style='color: green; font-size: large' class='fa-solid fa-check'></i>".html_safe
      when "не_пришёл"
        result = "<i style='margin: 0; color:red; font-size: large' class='fa-solid fa-xmark'></i>".html_safe
      when "выходной"
        result = "<i style='color:yellow; font-size: large' class='fa-regular fa-circle'></i>".html_safe
      end
    end
    result
  end

  def calculate_payment_by_participation(user_id, participations)
    user = User.find(user_id)
    return if user.daily_payment.nil?

    daily_payment = user.daily_payment
    number_of_active_days = participations.where(user_id: user_id).пришёл.count
    num_to_usd(number_of_active_days * daily_payment)
  end

  def active_tr(boolean)
    "table-danger" unless boolean
  end

  def strf_datetime(datetime, date = false)
    return if datetime.nil?

    if date
      datetime.strftime("%Y-%m-%d")
    else
      datetime.strftime("%Y-%m-%d %H:%M")
    end
  end

  def detect_danger_row(price, total_paid)
    return if [price, total_paid].any?(&:nil?) || (price == total_paid)

    if price > total_paid
      "table-danger"
    else
      "table-success"
    end
  end

  def find_by_price(pack)
    product_entries = pack.product_entries

    if product_entries.empty?
      currency_convert(pack.price_in_usd, pack.buy_price)
    else
      product_entry = product_entries.order(created_at: :asc).last
      currency_convert(product_entry.paid_in_usd, product_entry.buy_price)
    end
  end
end
