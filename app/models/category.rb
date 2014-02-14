class Category < ActiveRecord::Base
  validates_uniqueness_of :name

  attr_accessible :name

  has_many :categorizations, :dependent => :destroy
  has_many :projects, :through => :categorizations
end
