module Landscape
  class Client

    # Get all access groups in the account.
    # 
    # @param [Array<String>] names ([])  A list of access group names to get. Only matching access groups will be returned.
    # @return [Array<Hash>] the list of Access Groups.
    def get_access_groups(names = [])
      names = [names] if names.is_a? String
      params = names.empty? ? '' : Landscape.pathlist('names', names)
      fetch_response(action: 'GetAccessGroups', params: Landscape.pathlist('names', names))
    end

    # Get all roles in the account.
    # 
    # @param [Array<String>] names ([])  A a list of role names to get. Only matching roles will be returned.
    # @return [Array<Hash>] the list of Roles.
    def get_roles(names = [])
      names = [names] if names.is_a? String
      params = names.empty? ? '' : Landscape.pathlist('names', names)
      fetch_response(action: 'GetRoles', params: Landscape.pathlist('names', names))
    end

    # Get all available permissions.
    # @return [Array<Hash>] the list of Permissions.
    def get_permissions
      fetch_response(action: 'GetPermissions')
    end

    # Add the given access groups to a role.
    #
    # @param [String] name The name of the role to modify.
    # @param [Array<String>] access_groups A list of names of access groups to add.
    def add_access_groups_to_role(name, access_groups)
      params = {'name' => name}
      params.merge!(Landscape.pathlist('access_groups', access_groups))
      fetch_response(action: 'AddAccessGroupsToRole', params: params)
    end

    # Add the given permissions to a role.
    #
    # @param [String] name The name of the role to modify.
    # @param [Array<String>] permissions A list of names of permissions to add.
    def add_permissions_to_role(name, permissions)
      params = {'name' => name}
      params.merge!(Landscape.pathlist('permissions', permissions))
      fetch_response(action: 'AddPermissionsToRole', params: params)
    end

    # Add the given persons to a role. Those persons will be granted the role.
    #
    # @param [String] name The name of the role to modify.
    # @param [Array<String>] persons  A list of emails of persons to add.
    def add_persons_to_role(name, persons)
      params = {'name' => name}
      params.merge!(Landscape.pathlist('persons', persons))
      fetch_response(action: 'AddPersonsToRole', params: params)
    end

    # Create a new access group.
    #
    # @option options [String] :name ("") The name of the access group.
    # @option options [String] :title ("") The title of the access group.
    # @option options [String] :parent ("") Parent access group for new group.
    def create_access_group(options)
      raise ArgumentError, 'No :name' if options[:name].nil? || options[:name].empty?
      fetch_response(action: 'CreateAccessGroup', params: options)      
    end

    # Create a new role.
    #
    # @option options [String] :name ("") The name of the role.
    # @option options [String] :description ("") The description of the role.
    def create_role(options)
      raise ArgumentError, 'No :name' if options[:name].nil? || options[:name].empty?
      fetch_response(action: 'CreateRole', params: options)      
    end

    # Remove an access group.
    #
    # @param [String] name The name of the access group to remove.
    def remove_access_group(name)
      raise ArgumentError, 'No name provided' if name.nil? || name.empty?
      params = {'name' => name}
      fetch_response(action: 'RemoveAccessGroup', params: params)
    end

    # Remove the given access groups from a role.
    #
    # @param [String] name The name of the role to modify.
    # @param [Array<String>] access_groups A list of names of access groups to remove.
    def remove_access_groups_from_role(name, access_groups)
      params = {'name' => name}
      params.merge!(Landscape.pathlist('access_groups', access_groups))
      fetch_response(action: 'RemoveAccessGroupsFromRole', params: params)
    end

    # Remove the given permissions from a role.
    #
    # @param [String] name The name of the role to modify.
    # @param [Array<String>] permissions A list of names of permissions to remove.
    def remove_permissions_from_role(name, permissions)
      params = {'name' => name}
      params.merge!(Landscape.pathlist('permissions', permissions))
      fetch_response(action: 'RemovePermissionsFromRole', params: params)
    end
  end
end