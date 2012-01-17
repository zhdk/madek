# encoding: utf-8


module DataFactory 
  extend self

  def create_dag 
    prev_media_set = FactoryGirl.create :media_set
    (1..10).each do |i|
      next_media_set = FactoryGirl.create :media_set
      MediaSetArc.create_edge prev_media_set, next_media_set
      prev_media_set = next_media_set
    end
  end
end


FactoryGirl.define do

  ### Meta

  factory :meta_context do
    name {Faker::Lorem.words.join("_")}
    is_user_interface true
  end

  ### Media ....

  factory :media_set_arc do
  end

  factory :media_entry do
    upload_session {FactoryGirl.create :upload_session}
    media_file {FactoryGirl.create :media_file}
    after_build do |me|
      def me.extract_subjective_metadata; end
      def me.set_copyright; end
      def me.set_descr_author_value; end
    end
  end

  factory :media_file  do 
    uploaded_data  {{ :type=> "image/png", :tempfile=> File.new("#{Rails.root}/app/assets/images/icons/eye.png", "r"), :filename=> "eye.png"}} 
    content_type "image/png"
    guid  (Digest::SHA1.hexdigest Time.now.to_f.to_s)
    filename  "dummy.png"
    access_hash  UUIDTools::UUID.random_create.to_s
    after_build do |mf|
      def mf.assign_access_hash; end
      def mf.validate_file; end
      def mf.store_file; end
    end
  end

  factory :media_set do
    user {User.find_random || (FactoryGirl.create :user)}
  end

  ### Permissions ...

  factory :permission do
    subject {FactoryGirl.create :user}
    media_resource {FactoryGirl.create :media_set,:user => (FactoryGirl.create :user)}
    after_build do |perm| 
      user_default_permissions = {:view => false, :edit => false, :manage => false, :hi_res => false}
      perm.set_actions user_default_permissions
    end
  end


  ### Groups, Users, ....

  factory :group do
    name {Faker::Name.last_name}
  end

  factory :person do
    lastname {Faker::Name.last_name}
    firstname {Faker::Name.first_name}
  end

  factory :upload_session do
    user {User.find_random || (FactoryGirl.create :user)}
    is_complete true
  end

  factory :user do
    person {FactoryGirl.create :person}
    email {Faker::Internet.email}
    login {Faker::Internet.user_name}
    usage_terms_accepted_at {Time.now}
  end

end
