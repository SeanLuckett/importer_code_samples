require 'import_errors'

module PremiumPhysician
  class AddressMatcher
    def self.match?(address_1, address_2)
      begin
        (address_1.number == address_2.number) &&
          (match_street_name_within?(address_1, address_2, (0..2))) &&
          (address_1.unit == address_2.unit) &&
          (address_1.postal_code == address_2.postal_code)
      rescue
        false
      end
    end

    def self.match_street_name_within?(address_1, address_2, threshold)
      begin
        threshold.cover?(Text::Levenshtein.distance(address_1.street, address_2.street))
      rescue
        false
      end
    end
  end
end

