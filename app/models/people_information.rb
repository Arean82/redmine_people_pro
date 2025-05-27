class PeopleInformation < ActiveRecord::Base
  self.table_name = "people_information"
  self.primary_key = 'user_id'

  belongs_to :person, foreign_key: :user_id
  belongs_to :department

  # attr_accessible removed — use strong parameters in controllers

  def self.reject_information(attributes)
    exists = attributes['id'].present?

    # Manually list attribute names to check for emptiness (instead of accessible_attributes)
    attr_names = %w[
      phone address skype birthday job_title company middlename gender twitter
      facebook linkedin department_id background appearance_date is_system
    ]

    empty = attr_names.map { |name| attributes[name].blank? }.all?
    attributes.merge!({:_destroy => 1}) if exists && empty
    (!exists && empty)
  end
end
