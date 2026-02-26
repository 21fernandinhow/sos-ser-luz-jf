class HelpRequest < ApplicationRecord
  before_save :normalize_phone_to_digits

  validates :name, :address, :neighborhood, :need, presence: true

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
