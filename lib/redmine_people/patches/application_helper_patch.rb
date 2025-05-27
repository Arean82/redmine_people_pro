require_dependency 'application_helper'

module RedminePeople
  module Patches
    module ApplicationHelperPatch
      # Use prepend instead of alias_method_chain
      def self.prepended(base)
        base.class_eval do
          unloadable
        end
      end

      # Instance methods override
      def avatar(user, options = {})
        options[:width] ||= options[:size] || "50"
        options[:height] ||= options[:size] || "50"
        options[:size] = "#{options[:width]}x#{options[:height]}" if ActiveRecord::VERSION::MAJOR >= 4

        if user.blank? || user.is_a?(String) || (user.is_a?(User) && user.anonymous?)
          return super(user, options)
        end

        if user.is_a?(User) && (avatar = user.avatar)
          avatar_url = url_for only_path: false, controller: "people", action: "avatar", id: avatar, size: options[:size]
          image_tag(avatar_url, options.merge(class: "gravatar"))
        elsif user.respond_to?(:twitter) && !user.twitter.blank?
          image_tag("https://twitter.com/#{user.twitter}/profile_image?size=original", options.merge(class: "gravatar"))
        elsif !Setting.gravatar_enabled?
          image_tag('person.png', options.merge(plugin: "redmine_people", class: "gravatar"))
        else
          super(user, options)
        end
      end

      def link_to_user(user, options = {})
        if user.is_a?(User)
          name = h(user.name(options[:format]))
          if user.active? && User.current.allowed_people_to?(:view_people, user)
            link_to name, controller: 'people', action: 'show', id: user
          else
            name
          end
        else
          h(user.to_s)
        end
      end
    end
  end
end

# Prepend patch instead of include and alias_method_chain
ApplicationHelper.prepend(RedminePeople::Patches::ApplicationHelperPatch)
