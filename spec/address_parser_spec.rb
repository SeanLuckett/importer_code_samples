require 'spec_helper'
require 'import_helper'

describe PremiumPhysician::AddressParser do
  describe "#use_admin_area_if_present" do
    context "when facility isn't a database record" do
      let(:json_facility) { json_medical_facilities(0,0).first }

      it "doesn't change physical_state field" do
        parser = PremiumPhysician::AddressParser.new(json_facility)
        address = parser.send(:use_admin_area_if_present, json_facility)
        expect(address["physical_state"]).to eq "CO"
      end
    end

    context "when facility is a database record" do
      context "and has an administrative area" do
        context "when facility's physical_state field is nil" do
          it "deferrs to admin area for facility's physical_state field" do
            az_admin_area = FactoryGirl.create(:az)
            facility = FactoryGirl.create(:medical_facility, :phoenix, physical_state: nil, administrative_area: az_admin_area)

            parser = PremiumPhysician::AddressParser.new(facility)
            address = parser.send(:use_admin_area_if_present, facility)
            expect(address["physical_state"]).to eq "AZ"
          end
        end
      end

      context "and doesn't have an administrative area" do
        it "uses facility physical_state field" do
          facility = FactoryGirl.create(:medical_facility, :phoenix)
          parser = PremiumPhysician::AddressParser.new(facility)

          address = parser.send(:use_admin_area_if_present, facility)
          expect(address["physical_state"]).to eq "AZ"
        end
      end
    end
  end

  describe "#full_address" do
    it "removes punctuation" do
      address_data = json_medical_facilities.first.merge("physical_street" => "12 FIRST N. AVE.")
      parser = PremiumPhysician::AddressParser.new(address_data)
      expect(parser.send(:full_address)).to eq "12 FIRST N AVE DENVER CO 80202"
    end

    it "removes extra spaces" do
      address_data = json_medical_facilities.first.merge("physical_street" => "12        FIRST ST")
      parser = PremiumPhysician::AddressParser.new(address_data)
      expect(parser.send(:full_address)).to eq "12 FIRST ST DENVER CO 80202"
    end

    it "ensures address is in all capital letters" do
      address_data = json_medical_facilities.first.merge("physical_street" => "123 main st")
      parser = PremiumPhysician::AddressParser.new(address_data)
      expect(parser.send(:full_address)).to eq "123 MAIN ST DENVER CO 80202"
    end
  end

  describe "#verify_address" do
    it "removes anything contained by parentheses within the physical_street_2 field" do
      address_data = json_medical_facilities.first.merge(
        "physical_street" => "16222 N 59TH AVE",
        "physical_street_2" => "STE A100, (Atrium)"
      )
      parser = PremiumPhysician::AddressParser.new(address_data)
      verified_address = parser.verify_address(address_data)
      expect(verified_address["physical_street_2"]).to eq "STE A100, "
    end
  end
end
