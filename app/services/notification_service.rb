class NotificationService
  def self.notify_admins(actor:, action:, notifiable:, data: {})
    User.admin.find_each do |admin|
      # Don't notify the actor if they are an admin
      next if admin.id == actor.id
      
      # Check preferences
      # Default to true if preference is not set
      preferences = admin.notification_preferences || {}
      next if preferences[action] == false

      Notification.create!(
        recipient: admin,
        actor: actor,
        action: action,
        notifiable: notifiable,
        data: data
      )
    end
  end
end
