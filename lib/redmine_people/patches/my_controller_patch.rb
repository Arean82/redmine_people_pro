module RedminePeople
  module Patches
    module MyControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          before_action :authorize_people, only: [:destroy]
        end
      end

      module InstanceMethods
        def authorize_people
          deny_access unless User.current.allowed_people_to?(:edit_people, User.current)
        end
      end
    end
  end
end

unless MyController.included_modules.include?(RedminePeople::Patches::MyControllerPatch)
  MyController.send(:include, RedminePeople::Patches::MyControllerPatch)
end
