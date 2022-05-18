class ReleaseChecksBulkDebit < BulkDebit
  self.transaction_reason = CreditWalletTransaction::Reasons.RELEASE_CHECKS
end