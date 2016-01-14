# creates a list of all vocabularies, with meta_keys and meta_key_definition.
#
meta_keys:  555
in vocs:     98
problems:    14 (can't determine vocabulary)
orphans:    443 (not in any context)
 -unused:    88 <http://medienarchiv.zhdk.ch/app_admin/meta_keys?button=&filter%5Bcontext%5D=&filter%5Bis_used%5D=false&filter%5Blabel%5D=&filter%5Bmeta_datum_object_type%5D=&utf8=✓>


# # helpers
require 'csv'

def mkdefs_by_meta_key_for(context)
  MetaKeyDefinition.where(context: context)
    .group_by(&:meta_key)
    .map do |mk, mkdefs|
      throw 'does not compute!' if mkdefs.length > 1 # sanity check for tom (1:1 relation)
      mkdef = mkdefs.first
      { meta_key: mk.attributes.deep_symbolize_keys
          .merge(id: "#{mkdef.context_id}:#{mk.id}".gsub(/\s/, '_').gsub(/ä/, 'ae').gsub(/ö/, 'oe').gsub(/ü/, 'ue'))
          .merge(description: mkdef.description, hint: mkdef.hint) # the current data in those ONLY belongs to the meta_key!
          .merge(position: mkdef.position) # nice to have
          .except(:is_extensible_list, :meta_terms_alphabetical_order, :created_at, :updated_at), # just for debugging
        mkdef: mkdef.attributes.deep_symbolize_keys
          .merge(description: nil, hint: nil) # we still allow them in context IF NEEDED - maybe leave them and delete in the end if identical to mk (some things will change when mapping to new core)
          .except(:id, :description, :hint, :meta_key_id, :created_at, :updated_at) # just for debugging
      }[:meta_key] # just for debugging
    end
end

def to_csv(meta_keys)
  cols = meta_keys.map(&:keys).first
  vals = meta_keys.map(&:values)
  ([cols] + vals).inject('') { |csv, row| csv << CSV.generate_line(row) }
end

# # main
# we start by choosing those contexts that are already "Vocabularies in Spirit",
# meaning mks and mkdefs have a 1:1 relationship:
vocabularies = (
  ContextGroup.find_by(name: :Medieneintrag).contexts +
  ContextGroup.find_by(name: :Kontexte).contexts)

list = vocabularies.map do |c|
  {
    vocabulary: c.attributes.except(:position, :context_group_id),
    meta_keys: mkdefs_by_meta_key_for(c)
  }
end

# btw:
# All the keys:
all_keys = MetaKey.all
# The keys that have a definitive vocabulary:
voc_keys = vocabularies.map(&:meta_key_definitions).flatten.map(&:meta_key)
# All keys that are somehow mentioned in a context:
all_context_keys = Context.all.map(&:meta_key_definitions).flatten.map(&:meta_key).uniq
# Orphans: keys not mentioned in any context:
orphans = (all_keys - all_context_keys)
# Problems: Keys that are in a context we can't automatically map to vocabulary:
problems = (all_context_keys - voc_keys) # count 14, MetaDatum count 9

binding.pry

# puts list.as_json.to_yaml

puts to_csv(list.map {|v| v[:meta_keys]}.flatten)
