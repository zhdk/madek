class Userpermission < ActiveRecord::Base 
  belongs_to :user
  belongs_to :resource, :polymorphic => true
#
#  has_one :media_sets_userpermissions_join
#  has_one :media_set, through: :media_sets_userpermissions_join
#

end
