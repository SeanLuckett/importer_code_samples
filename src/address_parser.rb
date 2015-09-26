require 'street_address'

module PremiumPhysician
  class AddressParser
    def initialize(address)
      @address = verify_address(address)
    end

    def verify_address(address)
      usable_address = swap_numerals_for_words(address)
      usable_address = remove_parens_phrase(usable_address)
      verified_address = use_admin_area_if_present(usable_address)
      verified_address
    end

    def parse
      StreetAddress::US.parse(full_address)
    end

    private
    def full_address
      # remove non-word characters and extra spaces
      [
        @address["physical_street"],
        @address["physical_street_2"],
        @address["physical_city"],
        @address["physical_state"],
        @address["physical_zip"][0..4]
      ].join(' ').gsub(/\W/, ' ').squeeze(' ').upcase
    end

    def remove_parens_phrase(address)
      suite = address["physical_street_2"].to_s

      if suite.present?
        parens_phrase = ( suite.match( /\([\w\s]*\)/ ) ).to_s
        address["physical_street_2"] = suite.gsub(parens_phrase, "")
      end

      address
    end

    def swap_numerals_for_words(address)
      word_to_number_map = {
        "one" => "1", "two" => "2", "three" => "3", "four" => "4",
        "five" => "5", "six" => "6", "seven" => "7", "eight" => "8",
        "nine" => "9", "ten" => "10"
      }

      regexp = Regexp.compile( /^(#{word_to_number_map.keys.join("|")})/i )

      street = address["physical_street"]

      unless regexp.match(street).nil?
        address["physical_street"] = street.gsub(regexp, word_to_number_map[$1.downcase])
      end

      address
    end

    def use_admin_area_if_present(address)
      return address if address.class != MedicalFacility

      if address.administrative_area.present?
        address["physical_state"] = address.administrative_area.conventional_abbr
      end

      address
    end
  end
end
