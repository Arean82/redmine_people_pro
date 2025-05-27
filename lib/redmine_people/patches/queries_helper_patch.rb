require_dependency 'queries_helper'

module RedminePeople
  module Patches
    module QueriesHelperPatch
      def column_value(column, list_object, value)
        if list_object.is_a?(Person)
          case column.name
          when :id
            link_to value, person_path(value)
          when :gender
            value == 1 ? l(:label_people_female) : l(:label_people_male)
          when :name
            person_tag(list_object)
          when :status
            case value
            when Principal::STATUS_ACTIVE
              l(:status_active)
            when Principal::STATUS_REGISTERED
              l(:status_registered)
            when Principal::STATUS_LOCKED
              l(:status_locked)
            else
              value
            end
          when :department_id
            department_tree_tag(list_object)
          when :tags
            value.map(&:name).join(", ")
          else
            super
          end
        else
          super
        end
      end
    end
  end
end

# Apply the patch with `prepend`
QueriesHelper.prepend(RedminePeople::Patches::QueriesHelperPatch)
