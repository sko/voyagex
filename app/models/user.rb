class User < ActiveRecord::Base
  has_many :locations_users
  has_many :locations, through: :locations_users

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         #:async,
         :confirmable
end
