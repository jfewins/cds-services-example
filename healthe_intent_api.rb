require 'faraday'
require 'json'

class HealtheIntentApi
  def initialize(baseUrl, bearerToken)
    @connection = Faraday.new(url: baseUrl) do |conn|
      conn.response :logger, nil, { bodies: true }
      conn.headers = {
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{bearerToken}"
      }
    end
  end

  def patient_id_lookup(population_id, data_partition_id, source_patient_id)
    resp = @connection.get("/patient/v1/populations/#{population_id}/patient-id-lookup") do |req|
      req.params['dataPartitionId'] = data_partition_id
      req.params['sourcePersonId'] = source_patient_id
    end

    if resp.success?
      return JSON.parse(resp.body);
    else
      return nil
    end
  end

  def get_prior_diagnoses(pipeline_id, patient_id)
    resp = @connection.get("/condition-identification/v1/pipelines/#{pipeline_id}/patients/#{patient_id}/prior-diagnoses")

    if resp.success?
      return JSON.parse(resp.body);
    else
      return []
    end
  end

  def create_suppression(pipeline_id, patient_id, condition_identification_definition_id, suppression_reason_type, created_by)
    request_body = {
      patient: {
        id: patient_id
      },
      pipeline: {
        id: pipeline_id
      },
      conditionIdentificationDefinition: {
        id: condition_identification_definition_id
      },
      reasonType: suppression_reason_type,
      createdBy: {
        type: "SYSTEM",
        reference: {
          id: created_by
        }
      }
    }

    puts request_body
    resp = @connection.post("/condition-identification/v1/pipelines/#{pipeline_id}/patients/#{patient_id}/suppressions",
      request_body.to_json,
      "Content-Type" => "application/json")

    if resp.success?
      return JSON.parse(resp.body);
    end
  end
end