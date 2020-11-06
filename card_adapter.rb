require 'addressable/template'
require 'pry'
require 'securerandom'

class CardAdapter
  def initialize(tenant_mnemonic, base_api_url, population_id, pipeline_id, patient_id = nil)
    @tenant_mnemonic = tenant_mnemonic
    @base_api_url = base_api_url
    @population_id = population_id
    @pipeline_id = pipeline_id
    @patient_id = patient_id
  end

  def card_uuid(condition_identification_definition_id)
    "#{@base_api_url}/condition-identification/v1/pipelines/#{@pipeline_id}/patients/#{@patient_id}/prior-diagnoses?conditionIdentificationDefinitionId=#{condition_identification_definition_id}"
  end

  def card_uuid_values(card_uuid)
    template = Addressable::Template.new(
      "#{@base_api_url}/condition-identification/v1/pipelines/{pipeline_id}/patients/{patient_id}/prior-diagnoses?conditionIdentificationDefinitionId={condition_identification_definition_id}"
    )
    uri = Addressable::URI.parse(card_uuid)
    template.extract(uri)
  end

  def to_cards(prior_diagnoses)
    cards = prior_diagnoses['items'].map do |item|
      suggestions = item['recommendationMessages'].map do |rm|
        {
          label: rm['recommendationPolicy']['title'],
          uuid: SecureRandom.uuid,
          isRecommended: true,
          actions: [
            {
              type: 'create',
              description: rm['message']
            }
          ]
        }
      end

      {
        uuid: card_uuid(item['conditionIdentificationDefinition']['id']),
        summary: "Prior Dx: #{item['conditionIdentificationDefinition']['name']}",
        indicator: 'info',
        detail: item['recommendationMessages'][0]['message'],
        overrideReasons:[
          {
             code: "REJECT",
             system: "#{@base_api_url}/condition-identification/v1/suppressions#reasonType",
             display:"Reject"
          },
          {
             code:"RESOLVE",
             system: "#{@base_api_url}/condition-identification/v1/suppressions#reasonType",
             display:"Resolve"
          }
       ],
        source: {
          label: 'Cerner Standard - Condition Identification',
          url: 'https://wiki.cerner.com/display/HCIP/Condition+Identification'
        },
        links: [
          {
            label: 'Launch Diagnosis Insights',
            url: "https://#{@tenant_mnemonic}.diagnosisinsights.us.healtheintent.com/populations/#{@population_id}/patients/#{@patient_id}/condition-insights",
            type: 'absolute'
          }
        ]
      }
    end

    { 'cards': cards }
  end
end