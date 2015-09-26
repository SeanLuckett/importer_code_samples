require 'spec_helper'
require 'import_helper'

describe StandardPhysician::MedicalFacilityManager, clean_db: true do
  describe "#initialize" do
    let(:facility_manager) { StandardPhysician::MedicalFacilityManager.new(facilities, facility_json) }
    let(:facility_json)        { json_medical_facilities(0,2) }
    let!(:facilities) do
      facilities = []
      facilities << FactoryGirl.create(:medical_facility, json_medical_facilities.first)
      facilities << FactoryGirl.create(:medical_facility, json_medical_facilities(1,1).first)
      facilities << FactoryGirl.create(:medical_facility, json_medical_facilities(3,3).first)
      facilities
    end

    it "assigns matching facilities to instance variable" do
      expect(
        facility_manager.matching_facilities
      ).to match_array [facilities.first, facilities.second]
    end

    it "deletes non-matching facilities from database" do
      expect {
        StandardPhysician::MedicalFacilityManager.new(facilities, facility_json)
      }.to change{ MedicalFacility.count }.from(3).to(2)
    end

    describe "#map_facility_ids" do
      it "preserves the json facilities" do
        expect(facility_manager.mapped_json.count).to eq 3
      end

      it "maps database ids to json when addresses match" do
        expect(
          facility_manager.mapped_json.first["id"]
        ).to eq facilities.first.id

        expect(
          facility_manager.mapped_json.second["id"]
        ).to eq facilities.second.id
      end

      it "doesn't map ids to non-matching json addresses" do
        expect(
          facility_manager.mapped_json.last.has_key? "id"
        ).to be_false
      end
    end
  end

  describe "removing duplicate, matching facility addresses when initializing" do
    context "when duplicate has no aetna data" do
      let(:duplicate_json)        { json_medical_facilities(2,2) }
      let!(:duplicate_facilities) do
        dupes = []
        dupes << FactoryGirl.create(:medical_facility, json_medical_facilities(2,2).first)
        dupes << FactoryGirl.create(:medical_facility, json_medical_facilities(2,2).first)
        dupes
      end

      it "destroys one of them" do
        expect {
          StandardPhysician::MedicalFacilityManager.new(duplicate_facilities, duplicate_json)
        }.to change{ MedicalFacility.count }.from(2).to(1)
      end
    end

    context "when duplicate has aetna data" do
      it "destroys the non-aetna facility" do
        f1 = FactoryGirl.create(:medical_facility, json_medical_facilities(2,2).first)
        f2 = FactoryGirl.create(:medical_facility, :with_aetna_carrier_provider, json_medical_facilities(2,2).first)
        duplicate_facilities = [f1, f2]
        duplicate_json = [f1.as_json["medical_facility"]]
        manager = StandardPhysician::MedicalFacilityManager.new(duplicate_facilities, duplicate_json)
        expect(manager.matching_facilities).to match_array [f2]
      end
    end

    context "when more than one duplicate has aetna data" do
      it "destroys one of them" do
        f1 = FactoryGirl.create(:medical_facility, :with_aetna_carrier_provider, json_medical_facilities(2,2).first)
        f2 = FactoryGirl.create(:medical_facility, :with_aetna_carrier_provider, json_medical_facilities(2,2).first)
        duplicate_facilities = [f1, f2]
        duplicate_json = [f1.as_json["medical_facility"]]
        manager = StandardPhysician::MedicalFacilityManager.new(duplicate_facilities, duplicate_json)
        expect(manager.matching_facilities).to match_array [f1]
      end
    end
  end
end

