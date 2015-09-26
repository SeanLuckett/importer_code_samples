require 'spec_helper'
require 'import_helper'

describe PremiumPhysician::AddressMatcher do
  subject(:matcher) { PremiumPhysician::AddressMatcher.new }

  after :all do
    Physician.destroy_all
  end

  describe ".match?" do
    context "Matching addresses" do
      let(:db_facility) { PremiumPhysician::AddressParser.new(FactoryGirl.build(:medical_facility, :address_1)).parse }

      context "street names match exactly" do
        let(:matching_json_facility) { PremiumPhysician::AddressParser.new(json_medical_facilities(0,0).first).parse }

        it "returns true" do
          expect(
            PremiumPhysician::AddressMatcher.match?(matching_json_facility, db_facility)
          ).to be_true
        end
      end

      context "street names are within 2 levenshtein distance" do
        let(:matching_json_facility) do
          PremiumPhysician::AddressParser.new(
            json_medical_facilities.first.merge("physical_street" => "16222 N 59ST AVE STE A100")
          ).parse
        end

        it "returns true" do
          expect(
            PremiumPhysician::AddressMatcher.match?(matching_json_facility, db_facility)
          ).to be_true
        end
      end

      context "both addresses are ActiveRecord format" do
        let(:db_facility_1) { PremiumPhysician::AddressParser.new(FactoryGirl.build(:medical_facility, :address_1)).parse }
        let(:db_facility_2) { PremiumPhysician::AddressParser.new(FactoryGirl.build(:medical_facility, :address_1)).parse }

        it "returns true" do
          expect(
            PremiumPhysician::AddressMatcher.match?(db_facility_1, db_facility_2)
          ).to be_true
        end
      end

      context "both addresses are json format" do
        let(:json_facility_1) { PremiumPhysician::AddressParser.new(json_medical_facilities(0,0).first).parse }
        let(:json_facility_2) { PremiumPhysician::AddressParser.new(json_medical_facilities(0,0).first).parse }

        it "returns true" do
          expect(
            PremiumPhysician::AddressMatcher.match?(json_facility_1, json_facility_2)
          ).to be_true
        end
      end
    end

    context "Non-matching addresses" do
      let(:db_facility) { PremiumPhysician::AddressParser.new(FactoryGirl.build(:medical_facility, :address_1)).parse }

      context "Street name doesn't match" do
        let(:non_street_matching_facility) do
          PremiumPhysician::AddressParser.new(
            json_medical_facilities.first.merge("physical_street" => "16222 WEST MAIN ST STE A100")
          ).parse
        end

        it "returns false" do
          expect(
            PremiumPhysician::AddressMatcher.match?(non_street_matching_facility, db_facility)
          ).to be_false
        end
      end

      context "Street number doesn't match" do
        let(:non_street_num_matching_facility) do
          PremiumPhysician::AddressParser.new(
            json_medical_facilities.first.merge("physical_street" => "123 N 59TH AVE STE A100")
          ).parse
        end

        it "returns false" do
          expect(
            PremiumPhysician::AddressMatcher.match?(non_street_num_matching_facility, db_facility)
          ).to be_false
        end
      end

      context "First 5 digits of zip code don't match" do
        let(:non_city_matching_facility) do
          PremiumPhysician::AddressParser.new(
            json_medical_facilities.first.merge("physical_zip" => "80020")
          ).parse
        end

        it "returns false" do
          expect(
            PremiumPhysician::AddressMatcher.match?(non_city_matching_facility, db_facility)
          ).to be_false
        end
      end

      context "when parsed address is nil" do
        it "returns false" do
          good_address = PremiumPhysician::AddressParser.new(json_medical_facilities.first).parse
          bad_address = nil

          expect(
            PremiumPhysician::AddressMatcher.match?(good_address, bad_address)
          ).to be_false
        end
      end
    end
  end

  describe ".match_street_name_within?" do
    describe "parameters: " do
      context "when they don't respond to .street" do
        it "returns false" do
          unusable_address = mock("InvalidAddressObject")
          unusable_address.stubs(:street).raises(NoMethodError)

          expect(
            PremiumPhysician::AddressMatcher.match_street_name_within?(unusable_address, unusable_address, (0..1))
          ).to be_false
        end
      end

      context "when threshhold isn't a range" do
        it "returns false" do
          usable_address = mock("AddressObject")
          usable_address.stubs(:street)

          expect(
            PremiumPhysician::AddressMatcher.match_street_name_within?(usable_address, usable_address, 1)
          ).to be_false
        end
      end
    end

    context "when address street names have a distance within the threshold's range" do
      it "returns true" do
        address_1 = PremiumPhysician::AddressParser.new(json_medical_facilities.first).parse
        address_2 = PremiumPhysician::AddressParser.new(json_medical_facilities.first.merge(
          "physical_street" => "16222 N 58TH AVE STE A100"
        )).parse

        expect(PremiumPhysician::AddressMatcher.match_street_name_within?(address_1, address_2, (0..2))).to be_true
      end
    end
  end
end

