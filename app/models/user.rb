class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Include default devise modules. Others available are:
  # :confirmable, :recoverable
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable, :trackable, :validatable, :token_authenticatable

  ## Database authenticatable
  field :email, type: String
  field :encrypted_password, type: String

  validates :email, presence: true, uniqueness: true, format: { with: /^([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/i }
  validates_presence_of :encrypted_password

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Token authenticatable
  field :authentication_token, type: String

  index({ email: 1 }, { unique: true, background: true })
  attr_accessible :email, :password, :password_confirmation, :remember_me, :created_at, :updated_at
  validates :email, presence: true, uniqueness: true, format: { with: /^([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/i }

  before_save :ensure_authentication_token
end
