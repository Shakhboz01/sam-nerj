# total paid might be null, it means provider paid fully at once
# ignored service_price
class ProductEntry < ApplicationRecord
  attr_accessor :barcode

  belongs_to :delivery_from_counterparty, optional: true
  has_one :provider, through: :delivery_from_counterparty
  has_one :user, through: :delivery_from_counterparty
  belongs_to :pack
  belongs_to :user, optional: true

  validates :amount, comparison: { greater_than: 0 }
  validates_presence_of :buy_price

  before_validation :set_sell_price
  before_validation :verify_delivery_from_counterparty_is_not_closed
  before_destroy :verify_delivery_from_counterparty_is_not_closed
  before_destroy :increment_pack_usage
  after_destroy :decrement_pack_remaining
  before_create :decrement_pack_usage
  after_create :update_delivery_currency
  after_create :increment_pack_remaining

  scope :paid_in_uzs, -> { where('paid_in_usd = ?', false) }
  scope :paid_in_usd, -> { where('paid_in_usd = ?', true) }
  scope :unsold, -> { where('amount > amount_sold') }

  private

  def decrement_pack_usage
    Packs::TogglePackRemaining.run(pack: pack, amount: amount, action: :decrement)
  end

  def increment_pack_usage
    Packs::TogglePackRemaining.run(pack: pack, amount: amount, action: :increment)
  end

  def decrement_pack_remaining
    return if delivery_from_counterparty.nil?

    pack.decrement!(:initial_remaining, amount)
  end

  def increment_pack_remaining
    return if delivery_from_counterparty.nil?

    pack.increment!(:initial_remaining, amount)
  end

  def set_sell_price
    return unless new_record?

    self.sell_price = pack.sell_price if sell_price.nil?
  end

  def verify_delivery_from_counterparty_is_not_closed
    return if delivery_from_counterparty.nil?
    return throw(:abort) if delivery_from_counterparty.closed? && sell_price == sell_price_before_last_save && amount >= amount_sold

    delivery_from_counterparty.decrement!(:total_price, buy_price)
  end

  def update_delivery_currency
    return if delivery_from_counterparty.nil? || delivery_from_counterparty.price_in_usd == paid_in_usd

    delivery_from_counterparty.update(price_in_usd: paid_in_usd)
  end
end
