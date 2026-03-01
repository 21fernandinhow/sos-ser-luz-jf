class HelpRequest < ApplicationRecord
  before_save :normalize_phone_to_digits

  STATUSES = %w[pending in_progress completed].freeze

  validates :name, :address, :neighborhood, :need, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :people_count, numericality: { only_integer: true, in: 1..6 }, allow_nil: true

  def pending?
    status == "pending"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  # Label for people_count (1 => "1 pessoa", 2 => "2 pessoas", 6 => "6 ou mais").
  def people_count_label
    return nil if people_count.blank?
    return "6 ou mais" if people_count == 6
    people_count == 1 ? "1 pessoa" : "#{people_count} pessoas"
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
