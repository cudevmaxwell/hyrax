# Need way to find way to stub current_user and RoleMapper in order to run these tests
require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )

describe Hydra::AccessControlsEnforcement do
 describe "build_lucene_query" do

   it "should return fields for all roles the user is a member of checking against the discover, access, read fields" do
     stub_user = User.new
     stub_user.stubs(:is_being_superuser?).returns false
     helper.stubs(:current_user).returns(stub_user)
     RoleMapper.stubs(:roles).with(stub_user.login).returns(["archivist", "researcher"])
     
     query = helper.send(:build_lucene_query, "string")
     
     ["discover","edit","read"].each do |type|
       query.should match(/_query_\:\"#{type}_access_group_t\:archivist/) and
       query.should match(/_query_\:\"#{type}_access_group_t\:researcher/)
     end
   end
   it "should return fields for all the person specific discover, access, read fields" do
     stub_user = User.new
     stub_user.stubs(:is_being_superuser?).returns false
     helper.stubs(:current_user).returns(stub_user)
     query = helper.send(:build_lucene_query, "string")
     ["discover","edit","read"].each do |type|
       query.should match(/_query_\:\"#{type}_access_person_t\:#{stub_user.login}/)
     end
   end
   describe "for superusers" do
     it "should return superuser access level" do
       stub_user = User.new
       stub_user.stubs(:is_being_superuser?).returns true
       helper.stubs(:current_user).returns(stub_user)
       query = helper.send(:build_lucene_query, "string")
       ["discover","edit","read"].each do |type|         
         query.should match(/_query_\:\"#{type}_access_person_t\:\[\* TO \*\]/)
       end
     end
     it "should not return superuser access to non-superusers" do
       stub_user = User.new
       stub_user.stubs(:is_being_superuser?).returns false
       helper.stubs(:current_user).returns(stub_user)
       query = helper.send(:build_lucene_query, "string")
       ["discover","edit","read"].each do |type|
         query.should_not match(/_query_\:\"#{type}_access_person_t\:\[\* TO \*\]/)
       end
     end
   end

 end
 
 it "should have necessary fieldnames from initializer" do
   Hydra.config[:permissions][:catchall].should_not be_nil
   Hydra.config[:permissions][:discover][:group].should_not be_nil
   Hydra.config[:permissions][:discover][:individual].should_not be_nil
   Hydra.config[:permissions][:read][:group].should_not be_nil
   Hydra.config[:permissions][:read][:individual].should_not be_nil
   Hydra.config[:permissions][:edit][:group].should_not be_nil
   Hydra.config[:permissions][:edit][:individual].should_not be_nil
   Hydra.config[:permissions][:owner].should_not be_nil
   Hydra.config[:permissions][:embargo_release_date].should_not be_nil
 end
 
 # SPECS FOR SINGLE DOCUMENT REQUESTS
 describe 'Get Document Permissions By Id' do
   before(:each) do
     @doc_id = 'hydrangea:fixture_mods_article1'
     @bad_id = "redrum"
     @response2, @document = helper.get_permissions_solr_response_for_doc_id(@doc_id)
   end

   it "should raise Blacklight::InvalidSolrID for an unknown id" do
     lambda {
       helper.get_permissions_solr_response_for_doc_id(@bad_id)
     }.should raise_error(Blacklight::Exceptions::InvalidSolrID)
   end

   it "should have a non-nil result for a known id" do
     @document.should_not == nil
   end
   it "should have a single document in the response for a known id" do
     @response2.docs.size.should == 1
   end
   it 'should have the expected value in the id field' do
     @document.id.should == @doc_id
   end
   it 'should have non-nil values for permissions fields that are set on the object' do
     @document.get(Hydra.config[:permissions][:catchall]).should_not be_nil
     @document.get(Hydra.config[:permissions][:discover][:group]).should_not be_nil
     @document.get(Hydra.config[:permissions][:edit][:group]).should_not be_nil
     @document.get(Hydra.config[:permissions][:edit][:individual]).should_not be_nil
     @document.get(Hydra.config[:permissions][:read][:group]).should_not be_nil
     
     # @document.get(Hydra.config[:permissions][:discover][:individual]).should_not be_nil
     # @document.get(Hydra.config[:permissions][:read][:individual]).should_not be_nil
     # @document.get(Hydra.config[:permissions][:owner]).should_not be_nil
     # @document.get(Hydra.config[:permissions][:embargo_release_date]).should_not be_nil
   end
 end

 describe "Get Document by custom unique id" do
=begin    
   # Can't test this properly without updating the "document" request handler in solr
   it "should respect the configuration-supplied unique id" do
     SolrDocument.should_receive(:unique_key).and_return("title_display")
     @response, @document = helper.get_permissions_solr_response_for_doc_id('"Strong Medicine speaks"')
     @document.id.should == '"Strong Medicine speaks"'
     @document.get(:id).should == 2007020969
   end
=end
   it "should respect the configuration-supplied unique id" do
     doc_params = helper.permissions_solr_doc_params('"Strong Medicine speaks"')
     doc_params[:id].should == '"Strong Medicine speaks"'
   end
 end
   

end


