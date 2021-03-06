# Note: git blame, most if not all of this was copied over
#
# this module is used to extract meta_data from an imported
# file and set meta_data for the media_entry
#
# there is a similar named module which sets data
# for the meta_data attribute of a media_file
#
module MediaResourceModules
  module MetaDataExtraction
    extend ActiveSupport::Concern
    module ClassMethods
    end



    # Handler for extracting some subjective meta-data from whatever file has been handed to us
    #
    #--
    # TODO - more sophisticated importing validations.. some files have a key with a blank entry.. useful! (ie the import will fail if we allow blanks through)
    # TODO - generally everything we get via exiftool will have File and System tags.. do we really want this in subjective MD?
    # TODO - IFD0 tags will contain a camera manufacturer, possibly followed by that manufacturers own data. Parse or not to parse..
    # NOTE - java jar files are zipped, hence the group tag in application
    #++
    def extract_and_process_subjective_metadata
      content_type = self.media_file.content_type
      return unless ["image", "audio", "video"].any? {|w| content_type.include? w }
      meta_arr = Exiftool.extract_madek_subjective_metadata self.media_file.file_storage_location, content_type 
      process_metadata Exiftool.filter_unwanted_fields(meta_arr,content_type)
    end

    private


    # TODO this is a mess !!! 
    def process_metadata meta_arr
      meta_arr.each do |tag_array_entry|
        tag_array_entry.each do |entry_key, entry_value|

          if entry_key =~ /^XMP-(expressionmedia|mediapro):UserFields/
            Array(entry_value).each do |s|
              entry_key, entry_value = s.split('=', 2)

              # TODO priority ??
              case entry_key
              when "Datum", "Datierung"
                meta_key = MetaKey.find_by_id "portrayed object dates"
              when "Autor/in"
                meta_key = MetaKey.find_by_id "author"
              else
                next
              end

              # TODO dry
              next if entry_value.blank? or entry_value == "-" or meta_data.detect {|md| md.meta_key == meta_key } # we do sometimes receive a blank value in metadata, hence the check.
              entry_value.gsub!(/\\n/,"\n") if entry_value.is_a?(String) # OPTIMIZE line breaks in text are broken somehow
              begin
                meta_data.build(:meta_key => meta_key, :value => entry_value )
              rescue
                # ignoring silently, don't blocking the import process
              end
            end
          else
            meta_key = MetaKey.meta_key_for(entry_key) 

            case meta_key.meta_datum_object_type
            when "MetaDatumKeywords", "MetaDatumPeople", 
              "MetaDatumUsers", "MetaDatumInstitutionalGroups", "MetaDatumMetaTerms" 
              Array[entry_value]
            else
              Array(entry_value)
            end.each do |value_s|
              next if value_s.blank? or meta_data.detect {|md| md.meta_key == meta_key } # we do sometimes receive a blank value in metadata, hence the check.
              value_s.gsub!(/\\n/,"\n") if value_s.is_a?(String) # OPTIMIZE line breaks in text are broken somehow
              begin
                meta_data.build(:meta_key => meta_key, :value => value_s)
              rescue Exception => e
                Rails.logger.error Formatter.exception_to_log_s(e)
              end
            end
          end

        end
      end
    end

    #temp#
    #  def extract_mediapro_userfields
    #  end

    # see mapping table on http://code.zhdk.ch/projects/madek/wiki/Copyright
    def set_copyright
      copyright_status = meta_data.detect {|md| ["copyright status"].include?(md.meta_key.label) }
      are_usage_or_url_defined = meta_data.detect {|md| ["copyright usage", "copyright url"].include?(md.meta_key.label) }

      if !copyright_status
        value = (are_usage_or_url_defined ? Copyright.custom : Copyright.default)
        meta_data.build(:meta_key => MetaKey.find_by_id("copyright status"), :value => value)
      elsif are_usage_or_url_defined 
        copyright_status.value = Copyright.custom
      end
    end

  end
end

