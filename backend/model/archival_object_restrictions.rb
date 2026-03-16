module ArchivalObjectRestrictions

  # Calculate whether any ancestor archival object or the root resource
  # has restrictions_apply set to true
  # Fetches all ancestors in a single query instead of recursive queries
  def calculate_ancestor_restrictions_apply(obj)
    # First check the root resource
    if obj.root_record_id
      root = Resource[obj.root_record_id]
      # Resource model uses 'restrictions' field (not 'restrictions_apply')
      return true if root && root.restrictions == 1
    end

    # Collect all ancestor IDs by walking up the tree
    ancestor_ids = []
    current_parent_id = obj.parent_id
    
    # Walk up the tree collecting parent IDs (iterative, not recursive)
    # Limit to 100 levels to prevent infinite loops (though ArchivesSpace trees are typically much shallower)
    max_depth = 100
    depth = 0
    
    while current_parent_id && depth < max_depth
      ancestor_ids << current_parent_id
      
      # Get the parent to find its parent_id
      # We need to query one at a time here to follow the chain
      parent = ArchivalObject.select(:id, :parent_id, :restrictions_apply)
                             .where(:id => current_parent_id)
                             .first
      
      break unless parent
      
      # If this parent has restrictions, return immediately
      return true if parent.restrictions_apply == 1
      
      # Move up to the next parent
      current_parent_id = parent.parent_id
      depth += 1
    end

    # No ancestors have restrictions
    false
  end

  # For batch processing efficiency, pre-calculate for multiple objects
  # Fetches ALL ancestors (not just immediate parents) to handle deep hierarchies
  def calculate_ancestor_restrictions_apply_batch(objs)
    result = {}
    
    # Pre-fetch all unique root records
    root_ids = objs.map(&:root_record_id).uniq.compact
    roots = Resource.filter(:id => root_ids).select(:id, :restrictions).all
    roots_by_id = Hash[roots.map { |r| [r.id, r] }]
    
    # Fetch ALL ancestors (not just immediate parents) by walking up the tree
    all_ancestor_ids = collect_all_ancestor_ids(objs)
    
    # Fetch all ancestors in ONE query
    ancestors = if all_ancestor_ids.any?
                  ArchivalObject.filter(:id => all_ancestor_ids)
                                .select(:id, :parent_id, :restrictions_apply)
                                .all
                else
                  []
                end
    
    ancestors_by_id = Hash[ancestors.map { |a| [a.id, a] }]
    
    # Cache for ancestor restrictions status
    cache = {}
    
    # Calculate for each object
    objs.each do |obj|
      result[obj.id] = calculate_with_preloaded_data(
        obj, 
        roots_by_id, 
        ancestors_by_id, 
        cache
      )
    end
    
    result
  end

  private

  # Collect all ancestor IDs for a batch of objects
  # This walks up the tree level by level to find all ancestors
  def collect_all_ancestor_ids(objs)
    all_ancestor_ids = Set.new
    current_level_ids = objs.map(&:parent_id).compact.uniq
    
    # Walk up the tree level by level
    max_depth = 100
    depth = 0
    
    while current_level_ids.any? && depth < max_depth
      all_ancestor_ids.merge(current_level_ids)
      
      # Fetch this level to find their parents
      parents = ArchivalObject.filter(:id => current_level_ids)
                              .select(:id, :parent_id)
                              .all
      
      # Get the parent_ids for the next level
      current_level_ids = parents.map(&:parent_id).compact.uniq
      depth += 1
    end
    
    all_ancestor_ids.to_a
  end

  # Calculate restriction status using preloaded data (no additional queries)
  def calculate_with_preloaded_data(obj, roots_by_id, ancestors_by_id, cache)
    # Check cache first
    return cache[obj.id] if cache.has_key?(obj.id)
    
    # Check root resource
    if obj.root_record_id
      root = roots_by_id[obj.root_record_id]
      if root && root.restrictions == 1
        cache[obj.id] = true
        return true
      end
    end

    # Walk up parent chain checking restrictions (using preloaded data)
    current_parent_id = obj.parent_id
    max_depth = 100
    depth = 0
    
    while current_parent_id && depth < max_depth
      parent = ancestors_by_id[current_parent_id]
      
      if parent
        if parent.restrictions_apply == 1
          cache[obj.id] = true
          return true
        end
        current_parent_id = parent.parent_id
      else
        # Parent not found in preloaded data - shouldn't happen but handle gracefully
        break
      end
      
      depth += 1
    end

    cache[obj.id] = false
    false
  end

end
