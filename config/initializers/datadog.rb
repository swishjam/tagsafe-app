Datadog.configure do |c|
  c.use :rails, service_name: "tagsafe-#{Rails.env}"
end