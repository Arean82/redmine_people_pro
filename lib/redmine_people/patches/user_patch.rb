require_dependency 'redmine/acts/attachable_global'

module RedminePeople
  module Patches
    module UserPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        # ✅ Include AttachableGlobal before class_eval so `acts_as_attachable_global` becomes available
        base.send(:include, Redmine::Acts::AttachableGlobal)

        base.class_eval do
          unloadable

          # ✅ This will now work
          acts_as_attachable_global

          if ActiveRecord::VERSION::MAJOR >= 4
            has_one :avatar, lambda {
              where("#{Attachment.table_name}.description = 'avatar'")
            }, class_name: 'Attachment', as: :container, dependent: :destroy
          else
            has_one :avatar, class_name: 'Attachment', as: :container,
                    conditions: "#{Attachment.table_name}.description = 'avatar'",
                    dependent: :destroy
          end

          def self.clear_safe_attributes
            @safe_attributes.collect! do |attrs, options|
              if attrs.collect!(&:to_s).include?('firstname') 
                [attrs - ['firstname', 'lastname', 'mail', 'custom_field_values', 'custom_fields'], options]
              else
                [attrs, options]
              end
            end
          end
          self.clear_safe_attributes

          safe_attributes 'firstname', 'lastname', 'mail', 'custom_field_values', 'custom_fields',
                          if: ->(user, current_user) {
                            current_user.allowed_people_to?(:edit_people, user)
                          }
        end
      end

      module InstanceMethods
        def project
          @project ||= Project.new
        end

        def allowed_people_to?(permission, person = nil)
          return true if admin?

          if person.is_a?(User) && person.id == id
            return true if permission == :view_people
            return true if permission == :edit_people && Setting.plugin_redmine_people['edit_own_data'].to_i > 0
          end

          return false unless RedminePeople.available_permissions.include?(permission)
          return true if permission == :view_people && !anonymous? && Setting.plugin_redmine_people['visibility'].to_i > 0

          (groups + [self]).any? { |principal| PeopleAcl.allowed_to?(principal, permission) }
        end
      end
    end
  end
end

unless User.included_modules.include?(RedminePeople::Patches::UserPatch)
  User.send(:include, RedminePeople::Patches::UserPatch)
end
