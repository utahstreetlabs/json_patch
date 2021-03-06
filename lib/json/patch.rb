require "json/patch/version"

module JSON
  class Patch
    attr_reader :hunks

    def initialize(hunks)
      @hunks = hunks.map {|h| Hunk.new(h)}
    end

    # Apply this patch to an object
    #
    # The object to be modified (which may be nested inside the object
    # in the method signature) MUST implement #apply_patch.
    #
    # #apply_patch should return true if the patch can be succesfully
    # applied and false otherwise.
    #
    # If any hunk in the patch cannot be applied successfully, the
    # PATCH rfc dictates that the entire patch MUST not be
    # applied. This atomicity must be handled by the #apply_patch
    # implementation.
    def apply_to(object)
      object.apply_patch(self)# if object.respond_to?(:apply_patch)
    end
  end

  class Hunk
    attr_reader :op, :path, :value

    def initialize(attributes={})
      op = case
           when attributes.has_key?('add') then 'add'
           when attributes.has_key?('remove') then 'remove'
           when attributes.has_key?('replace') then 'replace'
           end
      if op
        @op = op.to_sym
      else
        raise ArgumentError
      end
      self.path = attributes[op]
      @value = attributes['value']
    end

    def path=(path_string)
      raise ArgumentError if path_string and not path_string[0] == '/'
      path_string ||= ''
      @path = path_string.split('/').drop(1).map {|section| section.to_sym}
    end

    # Given a root object, resolve the paths in this patch.
    # Return a tuple of the object and element to be modified.
    #
    # For example (from the specs):
    #
    # OpenStruct.new(:foo => 1, :bar => OpenStruct.new(:baz => 2))
    # JSON::Hunk.new('add' => '/bar/baz').resolve_path(obj).should == [obj.bar, :baz]
    def resolve_path(object)
      path_to_element = path[0..-2]
      element = path[-1]
      [path_to_element.inject(object) {|o, e| o.send(e) }, element]
    end

    def ==(other)
      op == other.op and path == other.path and value = other.value
    end
  end
end
