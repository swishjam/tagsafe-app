class LowCreditsCreditWalletNotification < CreditWalletNotification
  self.tagsafe_email_klass = TagsafeEmail::LowCreditsWarning
end