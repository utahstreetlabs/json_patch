module Mongoid
  module Patchable
    # Apply a patch this this document.
    #
    # Currently assumes add_to_set and set operations will succeed.
    #
    # TODO: is there a better way to ensure atomicity of multiple
    # operations while avoiding race conditions from multiple clients?
    #
    # it looks like
    #
    # Preferences.collection.update({'user_id' => 1}, {'$addToSet' => {'follow_suggest_blacklist' => 4}, '$set' => {'hams' => 2}})
    #
    # would do this, but a) it needs to deal with multiple hunks
    # acting on the same attribute and b) it looks like mongoid
    # doesn't support this ootb. more research needed...
    #
    # TODO: support more than just :add
    # TODO: handle numeric path segments
    def apply_patch(patch)
      # compile operation information for verification
      ops = patch.hunks.map do |hunk|
        (obj, element) = hunk.resolve_path(self)
        [hunk, obj, element, obj.fields[element.to_s]]
      end

      if patch_ops_valid?(ops)
        # if something goes wrong here, raise an error to let the client
        # know the patch may be partially applied
        ops.each do |hunk, obj, element, field|
          value = hunk.value
          case hunk.op
          when :add
            case field.type.name
            when 'Array'
              obj.add_to_set(element, value)
            else
              obj.set(element, value)
            end
          else
            raise UnimplementedError
          end
        end
        true
      end
    end

    protected

    def patch_ops_valid?(ops)
      ops.inject(true) do |valid, (hunk, obj, element, field)|
        # only support add operations for now
        valid && hunk && (hunk.op == :add) && hunk.value && obj && element && field
      end
    end
  end
end
