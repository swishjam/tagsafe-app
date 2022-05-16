class UptimeChecksBulkDebit < BulkDebit
  self.transaction_reason = CreditWalletTransaction::Reasons.UPTIME_CHECKS
end