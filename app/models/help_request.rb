class HelpRequest < ApplicationRecord
  before_save :normalize_phone_to_digits

  STATUSES = %w[pending in_progress completed].freeze

  validates :name, :address, :neighborhood, :need, presence: true
  validates :status, inclusion: { in: STATUSES }

  def pending?
    status == "pending"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  # Returns phone with digits only for WhatsApp link (https://wa.me/55XXXXXXXXXXX).
  # Returns nil if phone is blank.
  def phone_digits_only
    return nil if phone.blank?
    phone.to_s.gsub(/\D/, "").presence
  end

  private

  def normalize_phone_to_digits
    return if phone.blank?
    self.phone = phone.to_s.gsub(/\D/, "")
    self.phone = nil if phone.empty?
  end
end
