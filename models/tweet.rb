class Tweet < ActiveRecord::Base
  belongs_to :user
  validates :twitter, uniqueness: true  
  
end