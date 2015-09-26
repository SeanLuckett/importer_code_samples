require 'spec_helper'
require 'import_helper'

describe StandardPhysician::AccountNetworkImporter do
  before :each do
    Resque.stubs(:enqueue).returns(true)

    importer.stubs(:run_processors)
    importer.stubs(:report_update_status)
  end

  after :all do
    Physician.destroy_all
  end

  context 'with account' do
    let(:account)  { FactoryGirl.create(:account) }
    let(:importer) { StandardPhysician::AccountNetworkImporter.new(json_data, account_id: account.id) }

    it 'assigns the account to physician' do
      physician = importer.run
      expect(physician.account.id).to eq account.id
    end
  end

  context 'without account' do
    let(:importer) { StandardPhysician::AccountNetworkImporter.new(json_data) }

    it 'never assigns the account' do
      importer.expects(:assign_account).never
      importer.run
    end
  end

  context 'with plan ids' do
    let(:importer)     { StandardPhysician::AccountNetworkImporter.new(json_data, plan_ids: ['42']) }

    before :each do
      FactoryGirl.create(:insurance_carrier_plan, id: 42)
    end

    it 'assigns the plan_ids and carrier provider' do
      physician = importer.run
      expect(physician.carrier_providers.count).to eq 1
    end
  end

  def json_data
    {
      'npi_number' => '0123456798',
      'last_name' => 'Smith',
      "medical_facilities_attributes" => json_medical_facilities
    }
  end
end

