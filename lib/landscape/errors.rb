module Landscape
  module Errors
    # All Landscape errors are superclassed by Error < RuntimeError
    class Error < RuntimeError; end

    # RBAC Errors
    class UnknownAccessGroups < Error; end
    class UnknownRole < Error; end
    class ReadOnlyRole < Error; end
    class InvalidPermissions < Error; end
    class UnknownPersons < Error; end
    class DuplicateAccessGroup < Error; end
    class InvalidAccessGroup < Error; end
    class DuplicateRole < Error; end
    class InvalidRoleName < Error; end
  end
end
