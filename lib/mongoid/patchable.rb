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
        ops.each_with_index do |(hunk, obj, element, field), index|
          value = hunk.value
          case hunk.op
          when :add
            process_add(obj, field, element, value)
          when :replace
            process_replace(obj, field, element, value)
          when :remove
            process_remove(obj, field, element, value)
          else
            raise "Illegal operation #{hunk.op} in hunk #{index}"
          end
        end
        true
      end
    end

    protected

    def process_add(obj, field, element, value)
      case field.type.name
      when 'Array'
        obj.add_to_set(element, (value.is_a?(Array) ? {'$each' => value} : value))
      when 'Hash'
        (key, val) = destructure_hash_value(value)
        obj.send("#{element}=", {}) if obj.send(element).nil?
        obj.send(element)[key] = val
        obj.save(validate: false)
      else
        obj.write_attribute(element, value)
        obj.save
      end
    end

    def process_replace(obj, field, element, value)
      case field.type.name
      when 'Array'
        obj.add_to_set(element, (value.is_a?(Array) ? {'$each' => value} : value))
      when 'Hash'
        (key, val) = destructure_hash_value(value)
        obj.send("#{element}=", {}) if obj.send(element).nil?
        obj.send(element)[key] = val
        obj.save(validate: false)
      else
        obj.write_attribute(element, value)
        obj.save
      end
    end

    def process_remove(obj, field, element, value = nil)
      case field.type.name
      when 'Array'
        obj.pull_all(element, (value.is_a?(Array) ? value : [value]))
      when 'Hash'
        (key, val) = destructure_hash_value(value)
        if obj.send(element).nil?
          obj.send("#{element}=", {})
        else
          obj.send(element).delete(key)
        end
        obj.save(validate: false)
      else
        obj.write_attribute(element, nil)
        obj.save
      end
    end

    def patch_ops_valid?(ops)
      ops.inject(true) do |valid, (hunk, obj, element, field)|
        return false unless valid && hunk && obj && element && field
        return !hunk.value.nil? if [:add, :replace].include?(hunk.op)
        return true if hunk.op == :remove
        false
      end
    end

    def destructure_hash_value(value)
      (key, value) = value.split(/\=/, 2)
      key.ends_with?('[]') ? [key.slice(0..-3), value.split(',')] : [key, value]
    end
  end
end
