class Commit < ActiveRecord::Base
  belongs_to :user

  scope :latest, -> () { order('timestamp desc').limit(1).first }
end
