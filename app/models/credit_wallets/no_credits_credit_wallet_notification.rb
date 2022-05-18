class NoCreditsCreditWalletNotification < CreditWalletNotification
  self.tagsafe_email_klass = TagsafeEmail::NoMoreCredits
end