require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

module ResourceMethodsSpec
  class MyController < ActionController::Base
    resources_controller_for :users
  end
  
  if Rails.respond_to?(:version) && Rails.version >= "2.3"
    describe "#new_resource" do
      it "should accept block syntax" do
        c = MyController.new
        c.resource_service = User
        c.stub!(:params).and_return({})
        r = c.send(:new_resource) do |u|
          u.login = "Fred"
        end
        r.should be_kind_of User
        r.login.should == "Fred"
      end
    end
  end
  
  describe "An rc for collection :users" do
    before do
      @controller = MyController.new
    end

    describe "when no enclosing resource" do
      it "#find_resource(<id>) should call User.find(<id>)" do
        User.should_receive(:find).with("42")
        @controller.send(:find_resource, "42")
      end
    
      it "#find_resources should call User.find(:all)" do
        User.should_receive(:find).with(:all)
        @controller.send(:find_resources)
      end

      it "#new_resource({}) should call User.new({})" do
        User.should_receive(:new).with({})
        @controller.send(:new_resource, {})
      end

      it "#destroy_resource(<id>) should call User.destroy(<id>)" do
        User.should_receive(:destroy).with("42")
        @controller.send(:destroy_resource, "42")
      end
    end
      
    describe "when an enclosing resource is added (a forum)" do
      before do
        @forum = Forum.create!
        @controller.send :add_enclosing_resource, @forum
      end
  
      it "#find_resource(<id>) should call forum.users.find(<id>)" do
        @forum.users.should_receive(:find).with("42")
        @controller.send(:find_resource, "42")
      end
  
      it "#find_resources should call forum.users.find(:all)" do
        @forum.users.should_receive(:find).with(:all)
        @controller.send(:find_resources)
      end

      it "#new_resource({}) should call forum.users.build({})" do
        @forum.users.should_receive(:build).with({})
        @controller.send :new_resource, {}
      end

      it "#destroy_resource(<id>) should call forum.users.destroy(<id>)" do
        @forum.users.should_receive(:destroy).with("42")
        @controller.send(:destroy_resource, "42")
      end
    end
  end
  
  module MyResourceMethods
  protected
    def new_resource(attrs = (params[resource_name] || {}), &block)
      "my new_resource"
    end
    
    def find_resource(id = params[:id])
      "my find_resource"
      
    end
    
    def find_resources
      "my find_resources"
    end
    
    def destroy_resource(id = params[:id])
      "my destroy_resource"
    end
  end
  
  class MyControllerWithMyResourceMethods < ActionController::Base
    resources_controller_for :users
    include MyResourceMethods
  end

  describe "A controller with resource methods mixed in after resources_controller_for" do
    before do
      @controller = MyControllerWithMyResourceMethods.new
      @controller.resource_service = User
    end
    
    it "#new_resource should call MyResourceMethods#new_resource" do
      @controller.send(:new_resource, {}).should == 'my new_resource'
    end

    it "#find_resource should call MyResourceMethods#find_resource" do
      @controller.send(:find_resource, 1).should == 'my find_resource'
    end

    it "#find_resources should call MyResourceMethods#new_resource" do
      @controller.send(:find_resources).should == 'my find_resources'
    end
    
    it "#destroy_resource should call MyResourceMethods#destroy_resource" do
      @controller.send(:destroy_resource).should == 'my destroy_resource'
    end
  end
end