require 'spec_helper'
require 'import_helper'

describe StandardPhysician::Importer do
  subject(:importer)     { StandardPhysician::Importer.new(json) }
  let(:json)             { physician_json }

  before :each do
    Resque.stubs(:enqueue).returns(true)
  end

  describe "processing and vailidating json" do
    let(:processors) { import_processors }

    before :each do
      Physician.stubs(:create!)
    end

    it "runs all the processors" do
      importer.expects(:run_processors).with(processors).once
      importer.run
    end
  end

  describe "importing the physician" do
    before :each do
      importer.stubs(:run_processors)
      importer.stubs(:report_update_status)
    end

    context "when the physician doesn't already exist in the database" do
      it "creates a new record" do
        Physician.expects(:create!).with json
        importer.run
      end
    end

    context "when physician already in database" do
      let(:existing_physician) { mock("Physician") }
      let(:med_facility)       { mock("MedicalFacility") }

      before :each do
        Physician.stubs(:where).returns([existing_physician])
        existing_physician.stubs(:present?).returns(true)
        existing_physician.stubs(:medical_facilities=)
        existing_physician.stubs(:medical_facilities).returns([med_facility])
      end

      it "updates the physician data" do
        importer.stubs(:manage_medical_facilities)
        existing_physician.expects(:update_attributes!).with json
        importer.run
      end

      describe "Handling medical facilities" do
        let(:facility_manager) { mock("MedicalFacilityManager") }

        before :each do
          StandardPhysician::MedicalFacilityManager.stubs(:new).returns facility_manager
          existing_physician.stubs(:update_attributes!)
          facility_manager.stubs(:matching_facilities)
          facility_manager.stubs(:mapped_json)
          facility_manager.stubs(:destroy_non_matching_facilities)
        end

        it "gets physician facilities matching json" do
          facility_manager.expects(:matching_facilities).once
          importer.run
        end

        it "maps the matching facility ids to json" do
          facility_manager.expects(:mapped_json).once
          importer.run
        end
      end
    end
  end
end

def physician_json
  {
    "npi_number" => "0123456789",
    "first_name" => "Charles",
    "last_name" => "Yeager",
    "medical_facilities_attributes" => json_medical_facilities
  }
end

def import_processors
  [
    {transform: [MedicalSpecialtiesIgnorer]},
    {validate:
     [
       AppointmentSettingValidator,
       MedicalDegreeValidator,
       MedicalSpecialtiesValidator,
       AddressValidator
     ]
    },
    {transform:
     [
       MedicalFacilitiesNameProcessor,
       ForeignLanguageProcessor,
       MedicalSpecialtiesProcessor,
       MedicalSchoolProcessor,
       MedicalDegreeProcessor
     ]
    }
  ]
end

