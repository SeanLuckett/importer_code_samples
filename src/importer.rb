
module StandardPhysician
  class Importer
    include BaseImporter

    transforms_with MedicalSpecialtiesIgnorer

    validates_with  AppointmentSettingValidator,
                    MedicalDegreeValidator,
                    MedicalSpecialtiesValidator,
                    AddressValidator

    transforms_with MedicalFacilitiesNameProcessor,
                    ForeignLanguageProcessor,
                    MedicalSpecialtiesProcessor,
                    MedicalSchoolProcessor,
                    MedicalDegreeProcessor

    on_import do
      if physician.present?
        manage_medical_facilities
        physician.update_attributes! json
        report_update_status(physician)
      else
        new_physician = Physician.create!(json)
        log('Physician created')
      end

      imported_physician = new_physician || physician

      Sunspot.index! imported_physician
      imported_physician
    end

    def log_failed_import
      queue_data = {
        'error' => reportable_error,
        'json' => json
      }

      $redis.rpush 'standard_physician_errors', queue_data.to_json
    end

    def log_successful_import
      queue_data = {
        'events' => events,
        'json' => json
      }

      $redis.rpush 'standard_physician_events', queue_data.to_json
    end

    private

    attr_accessor :json

    def facility_manager
      if json_facilities && physician
        @facility_manager ||= MedicalFacilityManager.new(physician.medical_facilities, json_facilities)
      end
    end

    def json_facilities
      @facilities ||= json['medical_facilities_attributes']
    end

    def manage_medical_facilities
      physician.medical_facilities = facility_manager.matching_facilities
      json['medical_facilities_attributes'] = facility_manager.mapped_json
    end

    def physician
      @physician ||= Physician.where(npi_number: json.fetch('npi_number')).first
    end

    def report_update_status(physician)
      if physician.updated_at >= 1.minute.ago
        log('Physician updated')
      else
        log('Physician not updated')
      end
    end
  end
end

