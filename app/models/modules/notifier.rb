module Notifier
  def self.included base
    base.extend ClassMethods
    base.include InstanceMethods
  end

  module ClassMethods
    CALLBACK_DICTIONARY = {
      create: :send_notification_on_create,
      destroy: nil,
      update: nil
    }

    def broadcast_notification(on: [], except: [])
      on = [on] if on.is_a?(Symbol)
      except = [except] if except.is_a?(Symbol)
      if on.any?
        on.each{ |method| send(CALLBACK_DICTIONARY[method]) }
      elsif except.any?
        callbacks = CALLBACK_DICTIONARY.dup
        except.each{ |method| callbacks.delete(method) }
        callbacks.each{ |method| send(callbacks[method]) }
      else
        # run on all callbacks...
        CALLBACK_DICTIONARY.each{ |_callback, method| send(method) }
        # raise MissingArgumentError, "Must provide either `on:` or `except:` to specify when to display notifications"
      end
    end

    def send_notification_on_create
      after_create_commit { 
        broadcast_notification_to_all!(after_create_notification_msg, notification_image_url)
        # broadcast_notification_to_all!(after_create_notification_msg, img)
      }
    end
  end

  module InstanceMethods
    def broadcast_notification_to_all!(message, img = nil)
      broadcast_prepend_to "#{domain_id}_domain_notifications_container", 
                            target: "#{domain_id}_domain_notifications_container", 
                            partial: 'partials/notification', 
                            locals: { message: message, image: img, model: self }
    end
  end
end