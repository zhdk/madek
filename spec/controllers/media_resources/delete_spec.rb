require 'spec_helper'

describe MediaResourcesController, type: :controller do
  include Controllers::Shared
  render_views

  before :each do
    FactoryGirl.create :usage_term 
    FactoryGirl.create :context_core
    @owner = FactoryGirl.create :user
    @user = FactoryGirl.create :user
  end

  describe "HTTP DELETE on one media_resource" do
    before :each do
      @media_resource = FactoryGirl.create :media_entry, user: @owner
    end

    context "by the owner" do
      it "should be successful and delete the media_resource" do
        delete :destroy, {format: "json", id: @media_resource.id}, valid_session(@owner) 
        expect(response).to be_success
        expect(MediaResource.where(id: @media_resource.id).first).to be_nil
      end
    end

    context "on a none existing mr" do
      it "should be success" do
        delete :destroy, {format: "json", id: SecureRandom.uuid}, valid_session(@owner) 
        expect(response).to be_success
      end
    end


    context "by some other user" do

      it "should not be successful, retain the media_resource and return forbidden" do
        delete :destroy, {format: "json", id: @media_resource.id}, valid_session(@user) 
        expect(response).not_to be_success
        expect(MediaResource.where(id: @media_resource.id).first).not_to be_nil
        expect(response.status).to eq 403
      end

      context "with view permission" do
        before :each do
          Userpermission.create media_resource: @media_resource, user: @user, view: true
        end
        it "should not be successful, retain the media_resource and return forbidden" do
          delete :destroy, {format: "json", id: @media_resource.id}, valid_session(@user) 
          expect(response).not_to be_success
          expect(MediaResource.where(id: @media_resource.id).first).not_to be_nil
          expect(response.status).to eq 403
        end
      end
      
      context "with edit permission" do
        before :each do
          Userpermission.create media_resource: @media_resource, user: @user, edit: true
        end
        it "should not be successful, retain the media_resource and return forbidden" do
          delete :destroy, {format: "json", id: @media_resource.id}, valid_session(@user) 
          expect(response).not_to be_success
          expect(MediaResource.where(id: @media_resource.id).first).not_to be_nil
          expect(response.status).to eq 403
        end
      end
      
      context "with manage permission" do
        before :each do
          Userpermission.create media_resource: @media_resource, user: @user, manage: true
        end
        it "should not be successful" do
          delete :destroy, {format: "json", id: @media_resource.id}, valid_session(@user) 
          expect(response).not_to be_success
        end
      end

    end

  end

end

