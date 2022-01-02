class ExecutedLambdaFunction < ApplicationRecord
  belongs_to :parent, polymorphic: true
  store :request_payload
  store :response_payload

  uid_prefix 'lam'

  def self.for(obj)
    find_by(parent: obj)
  end
end