class IntegrationConfig

  def self.tenant_mnemonic
    'cernerdemo'
  end

  def self.business_identifier_system
    'https://github.com/jfewins/cds-services-example'
  end

  def self.population_id
    '1424e81d-8cea-4d6b-b140-d6630b684a58'
  end

  def self.pipeline_id
    '33344c27-becf-49f5-be59-9ed5e3f49ad7'
  end

  def self.data_partition_id
    '8dee150d-505f-4635-b009-1bef63d7cf5a'
  end

  def self.bearer_token
    ENV['BEARER_TOKEN']
  end

  def self.system_account_id
    ENV['SYSTEM_ACCOUNT']
  end

end