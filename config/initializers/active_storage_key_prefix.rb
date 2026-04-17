# frozen_string_literal: true

module ActiveStorageKeyPrefix
  def self.prefix
    ENV.fetch('ACTIVE_STORAGE_KEY_PREFIX', '').to_s.strip.gsub(%r{\A/+|/+\z}, '')
  end

  def key
    return self[:key] if self[:key].present?

    generated_key = super
    prefix = ActiveStorageKeyPrefix.prefix

    return generated_key if prefix.blank?

    self[:key] = "#{prefix}/#{generated_key}"
  end
end

Rails.application.config.to_prepare do
  next if ActiveStorageKeyPrefix.prefix.blank?
  next if ActiveStorage::Blob < ActiveStorageKeyPrefix

  ActiveStorage::Blob.prepend(ActiveStorageKeyPrefix)
end
