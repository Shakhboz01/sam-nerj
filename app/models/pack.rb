class Pack < ApplicationRecord
  has_one_attached :image
  belongs_to :product_category
  belongs_to :pack_usage, optional: true
  has_many :product_size_colors
  has_many :pack_usages
  has_many :product_entries
  has_many :products
  enum unit: %i[шт кг метр кв другой]
  validates :sell_price, comparison: { greater_than: 0 }
  validates :name, presence: true
  before_validation :reset_name
  before_save :say_hi, if: :saved_change_to_initial_remaining?
  before_create :set_buy_price
  after_create :create_an_entry
  before_update :send_notify_on_remaining_change, if: :saved_change_to_initial_remaining?

  scope :positive_remaining, -> { where('initial_remaining > ?', 0) }
  scope :price_in_uzs, -> { where('price_in_usd = ?', false) }
  scope :price_in_usd, -> { where('price_in_usd = ?', true) }

  attr_accessor :delivery_id

  def product_size_colors_attributes=(product_size_colors_attributes)
    product_size_colors_attributes.each do |i, dog_attributes|
      next if dog_attributes.values.any?(&:empty?)

      size = Size.find_or_create_by(name: dog_attributes[:size])
      dog_attributes[:size_id] = size.id
      dog_attributes.delete('size')
      self.product_size_colors.build(dog_attributes)
    end
  end

  def calculate_product_remaining
    remaining_from_entries = product_entries.sum(:amount) - product_entries.sum(:amount_sold)
    remaining_from_entries + initial_remaining
  end

  def sell_price_based_on_sale_currency(in_usd, rate, is_buyer)
    price = is_buyer ? buy_price : sell_price
    return price if price_in_usd == in_usd

    if in_usd
      (price / rate).round(2)
    else
      (price * rate).round(2)
    end
  end

  def from_local_production?
    product_category.weight == 1
  end

  private

  def set_buy_price
    return unless buy_price.nil?

    self.buy_price = sell_price - (sell_price * 5 / 100)
  end

  def reset_name
    return unless new_record?

    size_names = ''
    product_size_colors.each do |product_size_color|
      size = product_size_color.size.name
      product_size_color.amount.times do
        size_names << " #{size}"
      end
    end
  end

  def send_notify_on_remaining_change
    message = "Tovar ostatkasi qo'lda o'zgartirildi \n
      Товар: #{name} \n
      Edi: #{initial_remaining_was} \n
      Endi: #{initial_remaining_was}"
    SendMessageJob.perform_later(message)
  end

  def create_an_entry
    entry = ProductEntry.new(
      paid_in_usd: price_in_usd,
      sell_price: sell_price,
      buy_price: buy_price,
      amount: initial_remaining,
      pack: self
    )
    entry.save(:validate => false)
  end
end
