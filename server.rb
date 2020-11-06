require 'sinatra'
require 'pry'
require './healthe_intent_api.rb'
require './card_adapter.rb'
require './integration_config.rb'
require 'json'

configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

get '/cds-services' do
  content_type :json
  patient_view_example = {
    hook: 'patient-view',
    id: 'condition-identification-recommendations-v1',
    title: 'Recommendations from Condition Identification',
    description: 'The CDS service that returns a card with recommendations for closing coding gaps ' \
                 'based on evaluation of condition identification rules.',
    prefetch: {
      patient: "Patient/{{context.patientId}}",
    }
  };

  { services: [patient_view_example]}.to_json
end

post '/cds-services/condition-identification-recommendations-v1' do
  content_type :json

  request_data = JSON.parse(request.body.read)

  # Look for a business identifier with my system identifier for the patient lookup
  business_id = request_data['prefetch']['patient']['identifier'].first{ |id| id[IntegrationConfig.business_identifier_system] }
  unless business_id
    status 404
    return
  end

  tenant_mnemonic = IntegrationConfig.tenant_mnemonic
  base_api_url = "https://#{tenant_mnemonic}.api.us.healtheintent.com"
  api_client = HealtheIntentApi.new(base_api_url, IntegrationConfig.bearer_token)

  population_id = IntegrationConfig.population_id
  data_partition_id = IntegrationConfig.data_partition_id
  resp = api_client.patient_id_lookup(population_id, data_partition_id, business_id['value'])

  unless resp
    status 404
    return
  end

  patient_id = resp['items'][0]['patient']['id']
  pipeline_id = IntegrationConfig.pipeline_id
  pds = api_client.get_prior_diagnoses(pipeline_id, patient_id)

  card_adapter = CardAdapter.new(tenant_mnemonic, base_api_url, population_id, pipeline_id, patient_id)
  card_adapter.to_cards(pds).to_json
end

post '/cds-services/condition-identification-recommendations-v1/feedback' do
  content_type :json

  request_data = JSON.parse(request.body.read)

  tenant_mnemonic = IntegrationConfig.tenant_mnemonic
  base_api_url = "https://#{tenant_mnemonic}.api.us.healtheintent.com"
  api_client = HealtheIntentApi.new(base_api_url, IntegrationConfig.bearer_token)

  request_data['feedback'].each do |card|
    if card['outcome'] != 'overridden' || card['overrideReason'] == nil
      next
    end

    tenant_mnemonic = IntegrationConfig.tenant_mnemonic
    population_id = IntegrationConfig.population_id
    pipeline_id = IntegrationConfig.pipeline_id
    system_account_id = IntegrationConfig.system_account_id
    suppression_reason_type = card['overrideReason']['reason']['code']

    card_adapter = CardAdapter.new(tenant_mnemonic, base_api_url, population_id, pipeline_id)
    patient_id = card_adapter.card_uuid_values(card['card'])['patient_id']
    condition_identification_definition_id = card_adapter.card_uuid_values(card['card'])['condition_identification_definition_id']

    api_client.create_suppression(pipeline_id, patient_id, condition_identification_definition_id, suppression_reason_type, system_account_id)
  end
end

options "*" do
  response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  200
end
