class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper

  def redis_configs
    json = {
      TAGSAFE_REDIS_HOSTNAME: URI.parse(ENV['REDIS_URL']).hostname,
      LAMBDA_CRON_JOB_DATA_STORE_REDIS_HOSTNAME: URI.parse(ENV[ENV['LAMBDA_CRON_JOB_DATA_STORE_REDIS_URL_ENV_NAME']]).hostname
    }
    cipher = OpenSSL::Cipher.new('aes-128-cbc')
    cipher.encrypt
    cipher.key = ENV['TAGSAFE_ENCRYPTION_SECRET_KEY']
    cipher.iv = ENV['TAGSAFE_ENCRYPTION_IV']
    encrypted = cipher.update(json.to_json) + cipher.final

    decipher = OpenSSL::Cipher.new('aes-128-cbc')
    decipher.decrypt
    decipher.key = params[:decrypt_secret_key]
    decipher.iv = params[:decrypt_iv]
    decrypted = decipher.update(encrypted) + decipher.final

    render json: JSON.parse(decrypted)
  rescue => e
    Rails.logger.error "Cannot retrieve `redis_configs` from endpoint: #{e.message}"
    head :bad_request
  end
end
