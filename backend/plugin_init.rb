require_relative 'model/archival_object_restrictions'

# Extend ArchivalObject to add ancestor_restrictions_apply field
ArchivesSpaceService.loaded_hook do
  # Extend the ArchivalObject class with our module
  ArchivalObject.class_eval do
    extend ArchivalObjectRestrictions
    
    # Override sequel_to_jsonmodel to add the computed ancestor_restrictions_apply field
    class << self
      alias_method :sequel_to_jsonmodel_without_restrictions, :sequel_to_jsonmodel
      
      def sequel_to_jsonmodel(objs, opts = {})
        jsons = sequel_to_jsonmodel_without_restrictions(objs, opts)
        
        # Calculate ancestor_restrictions_apply efficiently for batch operations
        if objs.is_a?(Array) && objs.length > 0
          restrictions_map = calculate_ancestor_restrictions_apply_batch(objs)
          
          jsons.zip(objs).each do |json, obj|
            json['ancestor_restrictions_apply'] = restrictions_map[obj.id]
          end
        elsif objs.respond_to?(:id)
          # Single object
          jsons['ancestor_restrictions_apply'] = calculate_ancestor_restrictions_apply(objs)
        end
        
        jsons
      end
    end
  end
end
