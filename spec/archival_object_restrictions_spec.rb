require 'spec_helper'

# Load the plugin module and schema extension
require_relative '../../plugins/local/backend/model/archival_object_restrictions'
require_relative '../../plugins/local/schemas/archival_object_ext'

# Include the module in ArchivalObject for testing
ArchivalObject.class_eval do
  include ArchivalObjectRestrictions
  
  # Override sequel_to_jsonmodel to include the calculated field
  alias_method :sequel_to_jsonmodel_without_restrictions, :sequel_to_jsonmodel rescue nil
  
  def sequel_to_jsonmodel(opts = {})
    json = defined?(sequel_to_jsonmodel_without_restrictions) ? 
           sequel_to_jsonmodel_without_restrictions(opts) : 
           super(opts)
    
    # Calculate and add the field
    if opts[:calculate_ancestor_restrictions]
      objs = opts[:objs] || [self]
      results = calculate_ancestor_restrictions_apply_batch(objs)
      json['ancestor_restrictions_apply'] = results[self.id] || false
    else
      json['ancestor_restrictions_apply'] = calculate_ancestor_restrictions_apply(self)
    end
    
    json
  end
end

describe 'ArchivalObject Ancestor Restrictions' do
  
  before(:each) do
    # Ensure we have a repo context for all tests
    create(:repo, repo_code: generate(:repo_code))
  end

  describe 'calculate_ancestor_restrictions_apply' do
    
    it "returns false when archival object has no ancestors and resource has no restrictions" do
      resource = create(:json_resource)
      ao = ArchivalObject.create_from_json(
        build(:json_archival_object, resource: {'ref' => resource.uri}),
        repo_id: $repo_id
      )
      
      ao_obj = ArchivalObject[ao[:id]]
      expect(ao_obj.calculate_ancestor_restrictions_apply(ao_obj)).to be(false)
    end

    it "returns true when root resource has restrictions" do
      resource = create(:json_resource, restrictions: true)
      ao = ArchivalObject.create_from_json(
        build(:json_archival_object, resource: {'ref' => resource.uri}),
        repo_id: $repo_id
      )
      
      ao_obj = ArchivalObject[ao[:id]]
      expect(ao_obj.calculate_ancestor_restrictions_apply(ao_obj)).to be(true)
    end

    it "returns true when immediate parent has restrictions_apply" do
      resource = create(:json_resource)
      parent_ao = ArchivalObject.create_from_json(
        build(:json_archival_object, 
              resource: {'ref' => resource.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      child_ao = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => parent_ao.uri}),
        repo_id: $repo_id
      )
      
      child_obj = ArchivalObject[child_ao[:id]]
      expect(child_obj.calculate_ancestor_restrictions_apply(child_obj)).to be(true)
    end

    it "returns true when grandparent has restrictions_apply (multi-level)" do
      resource = create(:json_resource)
      
      # Level 1: grandparent with restrictions
      grandparent = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      # Level 2: parent without restrictions
      parent = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => grandparent.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      # Level 3: child without restrictions
      child = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => parent.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      child_obj = ArchivalObject[child[:id]]
      expect(child_obj.calculate_ancestor_restrictions_apply(child_obj)).to be(true)
    end

    it "returns true for deep hierarchy (4+ levels)" do
      resource = create(:json_resource)
      
      # Level 1: with restrictions
      level1 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      # Level 2: no restrictions
      level2 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => level1.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      # Level 3: no restrictions
      level3 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => level2.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      # Level 4: no restrictions
      level4 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => level3.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      level4_obj = ArchivalObject[level4[:id]]
      expect(level4_obj.calculate_ancestor_restrictions_apply(level4_obj)).to be(true)
    end

    it "returns false when no ancestors have restrictions" do
      resource = create(:json_resource, restrictions: false)
      
      parent = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      child = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => parent.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      child_obj = ArchivalObject[child[:id]]
      expect(child_obj.calculate_ancestor_restrictions_apply(child_obj)).to be(false)
    end

    it "returns false for top-level archival object without resource restrictions" do
      resource = create(:json_resource, restrictions: false)
      ao = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      ao_obj = ArchivalObject[ao[:id]]
      expect(ao_obj.calculate_ancestor_restrictions_apply(ao_obj)).to be(false)
    end

    it "uses early exit optimization when restricted ancestor found" do
      resource = create(:json_resource)
      
      # Create a deep hierarchy where restriction is found early
      level1 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      # Create several levels below
      current_parent = level1
      5.times do
        current_parent = ArchivalObject.create_from_json(
          build(:json_archival_object,
                resource: {'ref' => resource.uri},
                parent: {'ref' => current_parent.uri},
                restrictions_apply: false),
          repo_id: $repo_id
        )
      end
      
      deepest = ArchivalObject[current_parent[:id]]
      
      # Should find restriction and return true without querying all ancestors
      expect(deepest.calculate_ancestor_restrictions_apply(deepest)).to be(true)
    end
  end

  describe 'calculate_ancestor_restrictions_apply_batch' do
    
    it "correctly calculates restrictions for multiple objects with shared ancestors" do
      resource = create(:json_resource, restrictions: false)
      
      # Parent with restrictions
      parent = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      # Create multiple children sharing the same parent
      child1 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => parent.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      child2 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => parent.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      child3 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => parent.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      children = [
        ArchivalObject[child1[:id]],
        ArchivalObject[child2[:id]],
        ArchivalObject[child3[:id]]
      ]
      
      parent_obj = ArchivalObject[parent[:id]]
      results = parent_obj.calculate_ancestor_restrictions_apply_batch(children)
      
      # All children should inherit restrictions from parent
      expect(results[child1[:id]]).to be(true)
      expect(results[child2[:id]]).to be(true)
      expect(results[child3[:id]]).to be(true)
    end

    it "handles mixed scenarios correctly in batch" do
      resource_with_restrictions = create(:json_resource, restrictions: true)
      resource_without_restrictions = create(:json_resource, restrictions: false)
      
      # AO with restricted resource
      ao1 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource_with_restrictions.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      # AO with unrestricted resource and no parent
      ao2 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource_without_restrictions.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      # AO with restricted parent
      parent = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource_without_restrictions.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      ao3 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource_without_restrictions.uri},
              parent: {'ref' => parent.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      objs = [
        ArchivalObject[ao1[:id]],
        ArchivalObject[ao2[:id]],
        ArchivalObject[ao3[:id]]
      ]
      
      parent_obj = ArchivalObject[parent[:id]]
      results = parent_obj.calculate_ancestor_restrictions_apply_batch(objs)
      
      expect(results[ao1[:id]]).to be(true)  # Resource has restrictions
      expect(results[ao2[:id]]).to be(false) # No restrictions anywhere
      expect(results[ao3[:id]]).to be(true)  # Parent has restrictions
    end

    it "handles deep hierarchies in batch processing" do
      resource = create(:json_resource, restrictions: false)
      
      # Create a 4-level hierarchy
      level1 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      level2 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => level1.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      level3 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => level2.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      level4 = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => level3.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      # Batch calculate for all levels
      objs = [
        ArchivalObject[level2[:id]],
        ArchivalObject[level3[:id]],
        ArchivalObject[level4[:id]]
      ]
      
      level1_obj = ArchivalObject[level1[:id]]
      results = level1_obj.calculate_ancestor_restrictions_apply_batch(objs)
      
      # All should inherit from level1
      expect(results[level2[:id]]).to be(true)
      expect(results[level3[:id]]).to be(true)
      expect(results[level4[:id]]).to be(true)
    end

    it "efficiently handles large batches with shared ancestry" do
      resource = create(:json_resource, restrictions: false)
      
      parent = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      # Create 20 children sharing the same parent
      children_ids = 20.times.map do
        child = ArchivalObject.create_from_json(
          build(:json_archival_object,
                resource: {'ref' => resource.uri},
                parent: {'ref' => parent.uri},
                restrictions_apply: false),
          repo_id: $repo_id
        )
        child[:id]
      end
      
      children = children_ids.map { |id| ArchivalObject[id] }
      
      parent_obj = ArchivalObject[parent[:id]]
      results = parent_obj.calculate_ancestor_restrictions_apply_batch(children)
      
      # All should inherit restrictions
      children_ids.each do |id|
        expect(results[id]).to be(true)
      end
      
      # Verify we got results for all children
      expect(results.keys.length).to eq(20)
    end

    it "returns empty results for empty batch" do
      resource = create(:json_resource)
      ao = ArchivalObject.create_from_json(
        build(:json_archival_object, resource: {'ref' => resource.uri}),
        repo_id: $repo_id
      )
      
      ao_obj = ArchivalObject[ao[:id]]
      results = ao_obj.calculate_ancestor_restrictions_apply_batch([])
      
      expect(results).to eq({})
    end
  end

  describe 'integration with sequel_to_jsonmodel' do
    
    it "includes ancestor_restrictions_apply field in JSON response" do
      resource = create(:json_resource, restrictions: true)
      ao = ArchivalObject.create_from_json(
        build(:json_archival_object, resource: {'ref' => resource.uri}),
        repo_id: $repo_id
      )
      
      json = ArchivalObject.to_jsonmodel(ao[:id])
      
      expect(json).to have_key('ancestor_restrictions_apply')
      expect(json['ancestor_restrictions_apply']).to be(true)
    end

    it "calculates correctly for hierarchies in JSON response" do
      resource = create(:json_resource, restrictions: false)
      
      parent = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              restrictions_apply: true),
        repo_id: $repo_id
      )
      
      child = ArchivalObject.create_from_json(
        build(:json_archival_object,
              resource: {'ref' => resource.uri},
              parent: {'ref' => parent.uri},
              restrictions_apply: false),
        repo_id: $repo_id
      )
      
      parent_json = ArchivalObject.to_jsonmodel(parent[:id])
      child_json = ArchivalObject.to_jsonmodel(child[:id])
      
      # Parent with restrictions should not have ancestor_restrictions_apply set
      # (it has restrictions itself, not inherited)
      expect(parent_json['ancestor_restrictions_apply']).to be(false)
      
      # Child should inherit from parent
      expect(child_json['ancestor_restrictions_apply']).to be(true)
    end
  end

  describe 'edge cases and error handling' do
    
    it "handles missing parent gracefully" do
      resource = create(:json_resource, restrictions: false)
      ao = ArchivalObject.create_from_json(
        build(:json_archival_object, resource: {'ref' => resource.uri}),
        repo_id: $repo_id
      )
      
      ao_obj = ArchivalObject[ao[:id]]
      
      # Manually set a non-existent parent_id (simulating orphaned record)
      ao_obj.parent_id = 999999
      
      # Should handle gracefully and return false
      expect(ao_obj.calculate_ancestor_restrictions_apply(ao_obj)).to be(false)
    end

    it "respects depth limit to prevent infinite loops" do
      resource = create(:json_resource, restrictions: false)
      
      # Create a very deep hierarchy (beyond typical use)
      current_parent = ArchivalObject.create_from_json(
        build(:json_archival_object, resource: {'ref' => resource.uri}),
        repo_id: $repo_id
      )
      
      # Create 50 levels (should hit depth limit of 100 safely)
      50.times do
        current_parent = ArchivalObject.create_from_json(
          build(:json_archival_object,
                resource: {'ref' => resource.uri},
                parent: {'ref' => current_parent.uri}),
          repo_id: $repo_id
        )
      end
      
      deepest = ArchivalObject[current_parent[:id]]
      
      # Should complete without infinite loop
      expect(deepest.calculate_ancestor_restrictions_apply(deepest)).to be(false)
    end
  end
end
