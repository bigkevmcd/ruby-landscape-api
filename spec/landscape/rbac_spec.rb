require 'spec_helper'

describe Landscape::Client do
  let(:landscape) { Landscape::Client.new(api_access_key: 'not a key',
                                          secret_access_key: 'not a secret') }
  before do
    Timecop.travel(Time.local(2012, 9, 14, 18, 12, 12))
  end

  describe '#add_access_groups_to_role' do
    it 'should request adding an access group to a role' do
      landscape.stub!(:fetch_response).with(action: 'AddAccessGroupsToRole',
                                            params: {'name' => 'MyRole', 'access_groups.1' => 'my-group'}).and_return([
        {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => [], 'persons' => [], 'access_groups' => ['my-group']}])

      landscape.add_access_groups_to_role('MyRole', ['my-group'])
    end

    it 'should request adding multiple groups to a role' do
      landscape.stub!(:fetch_response).with(
        action: 'AddAccessGroupsToRole',
        params: {'name' => 'MyRole', 'access_groups.1' => 'my-group', 'access_groups.2' => 'my-other-group'}).and_return([
          {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => [], 'persons' => [], 'access_groups' => ['my-group', 'my-other-group']}])

      landscape.add_access_groups_to_role('MyRole', ['my-group', 'my-other-group'])
    end

    it 'should raise an error on an unknown role' do
      landscape.stub!(:make_request).with('AddAccessGroupsToRole', {"name"=>"NonexistentRole", "access_groups.1"=>"my-group"}).and_return(
        stub(:body => '{"message": "Unknown role name: NonexistentRole", "error": "UnknownRole"}'))
      expect { landscape.add_access_groups_to_role('NonexistentRole', ['my-group']) }.to raise_error(Landscape::Errors::UnknownRole)
    end

    it 'should raise an error on an unknown access group' do
      landscape.stub!(:make_request).with('AddAccessGroupsToRole', {"name"=>"MyRole", "access_groups.1"=>"test1"}).and_return(
        stub(:body => '{"message": "Unknown access groups for account \'testing\': test1", "error": "UnknownAccessGroups"}'))
      expect { landscape.add_access_groups_to_role('MyRole', ['test1']) }.to raise_error(Landscape::Errors::UnknownAccessGroups)
    end

    it 'should raise an error when an access group is read-only' do
      landscape.stub!(:make_request).with('AddAccessGroupsToRole', {"name"=>"MyRole", "access_groups.1"=>"testa"}).and_return(
        stub(:body => '{"message": "The role \'MyRole\' is read-only", "error": "ReadOnlyRole"}'))
      expect { landscape.add_access_groups_to_role('MyRole', ['testa']) }.to raise_error(Landscape::Errors::ReadOnlyRole)
    end
  end

  describe '#add_permissions_to_role' do
    it 'should request adding a permission to a role' do
      landscape.stub!(:fetch_response).with(action: 'AddPermissionsToRole',
                                            params: {'name' => 'MyRole', 'permissions.1' => 'ExecuteScript'}).and_return([
        {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => ['ExecuteScript'], 'persons' => [], 'access_groups' => ['my-group']}])

      landscape.add_permissions_to_role('MyRole', ['ExecuteScript'])
    end

    it 'should request adding multiple permissions to a role' do
      landscape.stub!(:fetch_response).with(action: 'AddPermissionsToRole',
                                            params: {'name' => 'MyRole', 'permissions.1' => 'ExecuteScript', 'permissions.2' => 'ViewComputer'}).and_return([
        {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => ['ExecuteScript', 'ViewComputer'], 'persons' => [], 'access_groups' => ['my-group']}])

      landscape.add_permissions_to_role('MyRole', ['ExecuteScript', 'ViewComputer'])
    end

    it 'should raise an error on an unknown role' do
      landscape.stub!(:make_request).with('AddPermissionsToRole', {"name"=>"NonexistentRole", "permissions.1"=>"my-group"}).and_return(
        stub(:body => '{"message": "Unknown role name: NonexistentRole", "error": "UnknownRole"}'))
      expect { landscape.add_permissions_to_role('NonexistentRole', ['my-group']) }.to raise_error(Landscape::Errors::UnknownRole)
    end

    it 'should raise an error on an unknown permission' do
      landscape.stub!(:make_request).with('AddPermissionsToRole', {"name"=>"MyRole", "permissions.1"=>"test1"}).and_return(
        stub(:body => '{"message": "Invalid permissions: test1", "error": "InvalidPermissions"}'))
      expect { landscape.add_permissions_to_role('MyRole', ['test1']) }.to raise_error(Landscape::Errors::InvalidPermissions)
    end

    it 'should raise an error when a role is read-only' do
      landscape.stub!(:make_request).with('AddPermissionsToRole', {"name"=>"MyRole", "permissions.1"=>"ExecuteScript"}).and_return(
        stub(:body => '{"message": "The role \'MyRole\' is read-only", "error": "ReadOnlyRole"}'))
      expect { landscape.add_permissions_to_role('MyRole', ['ExecuteScript']) }.to raise_error(Landscape::Errors::ReadOnlyRole)
    end
  end

  describe '#add_persons_to_role' do
    it 'should request adding a person to a role' do
      landscape.stub!(:fetch_response).with(action: 'AddPersonsToRole',
                                            params: {'name' => 'MyRole', 'persons.1' => 'test@example.com'}).and_return([
        {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => [], 'persons' => ['test@example.com'], 'access_groups' => ['my-group']}])

      landscape.add_persons_to_role('MyRole', ['test@example.com'])
    end

    it 'should request adding more than one to a role' do
      landscape.stub!(:fetch_response).with(action: 'AddPersonsToRole',
                                            params: {'name' => 'MyRole', 'persons.1' => 'test@example.com', 'persons.2' => 'test2@example.com'}).and_return([
        {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => [], 'persons' => ['test@example.com', 'test2@example.com'], 'access_groups' => ['']}])

      landscape.add_persons_to_role('MyRole', ['test@example.com', 'test2@example.com'])
    end

    it 'should raise an error if an unknown email is known' do
      landscape.stub!(:make_request).with('AddPersonsToRole', {'name'=>'MyRole', 'persons.1'=>'test@example.com'}).and_return(
        stub(:body => '{"message": "Unknown persons emails: test@example.com", "error": "UnknownPersons"}'))
      expect { landscape.add_persons_to_role('MyRole', ['test@example.com']) }.to raise_error(Landscape::Errors::UnknownPersons)
    end
  end

  describe '#create_access_group' do
    it 'should request creation of an access group with a name' do
      landscape.stub!(:fetch_response).with(action: 'CreateAccessGroup', params: {name: 'Testing', title: 'Test Group', parent: 'global'}).and_return(
        {'children' => '', 'name' => 'Testing', 'parent' => 'global', 'title' => 'Test Group'})

      landscape.create_access_group(name: 'Testing', title: 'Test Group', parent: 'global')
    end
    it 'should raise an error if no name is supplied' do
      expect { landscape.create_access_group(title: 'Test Group') }.to raise_error(ArgumentError)
    end
    it 'should not raise an error if no title is supplied' do
      landscape.stub!(:fetch_response).with(action: 'CreateAccessGroup', params: {name: 'Testing', parent: 'global'}).and_return(
        {'children' => '', 'name' => 'Testing', 'parent' => 'global', 'title' => ''})
      landscape.create_access_group(name: 'Testing', parent: 'global')
    end
    it 'should not raise an error if no parent is supplied' do
      landscape.stub!(:fetch_response).with(action: 'CreateAccessGroup', params: {name: 'Testing', title: 'Test Group'}).and_return(
        {'children' => '', 'name' => 'Testing', 'parent' => '', 'title' => 'Test Group'})
      landscape.create_access_group(name: 'Testing', title: 'Test Group')
    end
    it 'should raise an error if we try to create a group with a duplicate name' do
      landscape.stub!(:make_request).with('CreateAccessGroup', {name: 'Testing', title: 'Test Group'}).and_return(
        stub(:body => '{"message": "Duplicate access group \'Testing\' \'TestGroup\'.", "error": "DuplicateAccessGroup"}'))
      expect { landscape.create_access_group(name: 'Testing', title: 'Test Group') }.to raise_error(Landscape::Errors::DuplicateAccessGroup)
    end
    it 'should raise an error if the name is invalid' do
      landscape.stub!(:make_request).with('CreateAccessGroup', {name: 'testing', title: 'Test Group'}).and_return(
        stub(:body => '{"message": "Invalid ", "error": "InvalidAccessGroup"}'))
      expect { landscape.create_access_group(name: 'testing', title: 'Test Group') }.to raise_error(Landscape::Errors::InvalidAccessGroup)
    end
  end
  describe '#create_role' do
    it 'should request creation of new role with a name' do
      landscape.stub!(:fetch_response).with(action: 'CreateRole', params: {name: 'Tester', description: 'Test Role'}).and_return(
        {'key' => 1012, 'name' => 'Tester', 'description' => 'Test Role', 'permissions' => [], 'persons' => [], 'access_groups' => []})

      landscape.create_role(name: 'Tester', description: 'Test Role')
    end
    it 'should raise an error if no name is supplied' do
      expect { landscape.create_role(description: 'Test Role') }.to raise_error(ArgumentError)
    end
    it 'should not raise an error if no title is supplied' do
      landscape.stub!(:fetch_response).with(action: 'CreateRole', params: {name: 'Testing'}).and_return(
        {'key' => 1012, 'name' => 'Tester', 'description' => '', 'permissions' => [], 'persons' => [], 'access_groups' => []})
      landscape.create_role(name: 'Testing')
    end
    it 'should raise an error if we try to create a group with a duplicate name' do
      landscape.stub!(:make_request).with('CreateRole', {name: 'Testing'}).and_return(
        stub(:body => '{"message": "Role \'Testing\' already exists.", "error": "DuplicateRole"}'))
      expect { landscape.create_role(name: 'Testing') }.to raise_error(Landscape::Errors::DuplicateRole)
    end
    it 'should raise an error if the name is invalid' do
      landscape.stub!(:make_request).with('CreateRole', {name: '2testing'}).and_return(
        stub(:body => '{"message": "Invalid ", "error": "InvalidRoleName"}'))
      expect { landscape.create_role(name: '2testing') }.to raise_error(Landscape::Errors::InvalidRoleName)
    end
  end

  describe '#get_access_groups' do
    it 'should fetch the unfiltered list of access groups' do
      landscape.stub!(:fetch_response).with(action: 'GetAccessGroups', params: {}).and_return(
        [{'children' => '', 'name' => 'my-computers', 'parent' => 'global', 'title' => 'My Computers'}, 
         {'children' => 'my-computers', 'name' => 'global', 'parent' => '', 'title' => 'Global access'}
        ])

      landscape.get_access_groups.length.should == 2
    end
    it 'should filter by name if supplied' do
      landscape.stub!(:fetch_response).with(action: 'GetAccessGroups', params: {'names.1' => 'Global'}).and_return(
        [{'children' => 'my-computers', 'name' => 'global', 'parent' => '', 'title' => 'Global access'}])

      landscape.get_access_groups(['Global']).length.should == 1
    end
    it 'should filter by multiple names if supplied' do
      landscape.stub!(:fetch_response).with(action: 'GetAccessGroups', params: {'names.1' => 'Global', 'names.2' => 'Testing'}).and_return(
        [{'children' => 'my-computers', 'name' => 'global', 'parent' => '', 'title' => 'Global access'}])

      landscape.get_access_groups(['Global', 'Testing']).length.should == 1
    end
    it 'should silently convert single names into arrays of names before sending' do
      landscape.stub!(:fetch_response).with(action: 'GetAccessGroups', params: {'names.1' => 'Global'}).and_return(
        [{'children' => 'my-computers', 'name' => 'global', 'parent' => '', 'title' => 'Global access'}])
      landscape.get_access_groups('Global').length.should == 1
    end

    it 'should raise an error on a non-existent access group' do
      landscape.stub!(:make_request).with('GetAccessGroups', {'names.1' => 'nonexistent'}).and_return(
        stub(:body => '{"message": "Unknown access groups for account \'testing\': nonexistent", "error": "UnknownAccessGroups"}'))
      expect { landscape.get_access_groups('nonexistent') }.to raise_error(Landscape::Errors::UnknownAccessGroups)
    end
  end

  describe '#get_permissions' do
    it 'should fetch all permissions in the account' do
      landscape.stub!(:fetch_response).with(action: 'GetPermissions').and_return([
        {'name' => 'ViewComputer', 'title' => 'View Computers'},
        {'name' => 'ManageComputer', 'title' => 'Manage Computers'}])
      landscape.get_permissions.length.should == 2
    end
  end

  describe '#get_roles' do
    it 'should fetch all roles in the account' do
      landscape.stub!(:fetch_response).with(action: 'GetRoles', params: {}).and_return([
        {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => [], 'persons' => [], 'access_groups' => []}])
      landscape.get_roles.length.should == 1
    end
    it 'should filter by name if supplied' do
      landscape.stub!(:fetch_response).with(action: 'GetRoles', params: {'names.1' => 'MyRole'}).and_return([
        {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => [], 'persons' => [], 'access_groups' => []}])
      landscape.get_roles(['MyRole']).length.should == 1
    end
    it 'should filter by multiple names if supplied' do
      landscape.stub!(:fetch_response).with(action: 'GetRoles', params: {'names.1' => 'Test1', 'names.2' => 'Test2'}).and_return([
        {'key' => 1012, 'name' => 'Test1', 'description' => '', 'permissions' => [], 'persons' => [], 'access_groups' => []},
        {'key' => 1013, 'name' => 'Test2', 'description' => '', 'permissions' => [], 'persons' => [], 'access_groups' => []}])

      landscape.get_roles(['Test1', 'Test2']).length.should == 2
    end
    it 'should silently convert single names into arrays of names before sending' do
      landscape.stub!(:fetch_response).with(action: 'GetRoles', params: {'names.1' => 'MyRole'}).and_return([
        {'key' => 1012, 'name' => 'MyRole', 'description' => '', 'permissions' => [], 'persons' => [], 'access_groups' => []}])
      landscape.get_roles('MyRole').length.should == 1
    end
  end

end