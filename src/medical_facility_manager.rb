module StandardPhysician
  class MedicalFacilityManager
    attr_reader :matching_facilities, :mapped_json

    # takes two arrays: 1. ActiveRecord medical facilities. 2. Facility json objects
    def initialize(facilities, json)
      @matching_facilities = separate_matching_facilities(facilities, json)
      @mapped_json = map_facility_ids(json)
    end

    def addresses_match?(facility_1, facility_2)
      PremiumPhysician::AddressMatcher.match?(
        PremiumPhysician::AddressParser.new(facility_1).parse,
        PremiumPhysician::AddressParser.new(facility_2).parse
      )
    end

    private

    def destroy_duplicates(dupes)
      dupes.each {|d| d.destroy }
    end

    def destroy_non_matching_facilities(facilities, matching_facilities)
      facilities.each do |facility|
        facility.destroy unless matching_facilities.include? facility
      end
    end

    def map_facility_ids(json)
      json.each do |json_facility|
        matched_facility = matching_facilities.detect{ |f| addresses_match?(json_facility, f) }
        if matched_facility.present?
          json_facility["id"] = matched_facility.id
        end
      end
    end

    def pick_one(facilities)
      aetna_facilities = facilities.select{|f| f.aetna_carrier_provider.present?}

      if aetna_facilities.count > 0
        aetna_facilities.first
      else
        facilities.first
      end
    end

    def remove_duplicate_matching_facility_addresses(facilities)
      return facilities if facilities.count < 2

      unique_facilities =  facilities.each_with_object([]) do |facility, keepers|
        dupes = facilities.select{|f| addresses_match?(f, facility)}
        keepers << pick_one(dupes)
      end.uniq.flatten

      destroy_duplicates(facilities - unique_facilities)
      unique_facilities
    end

    def separate_matching_facilities(facilities, json)
      matching_facilities = facilities.select{ |f|
        json.detect{ |json_facility| addresses_match?(f, json_facility) }
      }

      destroy_non_matching_facilities(facilities, matching_facilities)
      matching_facilities = remove_duplicate_matching_facility_addresses(matching_facilities)
      matching_facilities
    end
  end
end
