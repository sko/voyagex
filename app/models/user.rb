class User < ActiveRecord::Base
  has_many :locations_users, dependent: :destroy
  has_many :locations, through: :locations_users
  has_many :uploads

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         #:async,
         :confirmable

  def self.create_tmp_user
    User.create(username: tmp_id, email: 'sko', )
  end
end
