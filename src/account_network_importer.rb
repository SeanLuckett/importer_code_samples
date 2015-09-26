module StandardPhysician
  class AccountNetworkImporter < Importer
    transforms_with MedicalSpecialtiesIgnorer

    validates_with  AppointmentSettingValidator,
                    MedicalDegreeValidator,
                    MedicalSpecialtiesValidator,
                    AddressValidator

    transforms_with MedicalFacilitiesNameProcessor,
                    ForeignLanguageProcessor,
                    MedicalSpecialtiesProcessor,
                    MedicalSchoolProcessor,
                    ScrubAttributesProcessor,
                    MedicalDegreeProcessor

    def initialize(json, options = {})
      @json =       json.deep_dup
      @account_id = options[:account_id]
      @plan_ids   = options[:plan_ids]
      @events =     []
    end

    on_import do
      if physician.present?
        manage_medical_facilities
        physician.update_attributes!(json)
        report_update_status(physician)
      else
        new_physician = Physician.create!(json)
        log('Physician created')
      end

      imported_physician = new_physician || physician

      assign_account(imported_physician) if account_id.present?
      assign_carrier_provider(imported_physician.medical_facilities)

      Sunspot.index! imported_physician
      imported_physician
    end

    private

    attr_accessor :account_id, :plan_ids

    def assign_account(physician)
      physician.update_attributes!(account_id: account_id)
    end

    def assign_carrier_provider(facilities)
      if plan_ids.present?
        CarrierProvider.add_insurance_plans_to_facilities(facilities, plan_ids)
      end
    end
  end
end

