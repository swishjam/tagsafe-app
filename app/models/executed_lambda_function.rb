class ExecutedLambdaFunction < ApplicationRecord
  belongs_to :parent, polymorphic: true
  store :request_payload
  store :response_payload

  uid_prefix 'lam'
end