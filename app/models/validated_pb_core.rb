require 'nokogiri'
require_relative 'pb_core'

class ValidatedPBCore < PBCore
  @@schema = Nokogiri::XML::Schema(File.read('lib/pbcore-2.0.xsd'))

  def initialize(xml)
    super(xml)
    schema_validate(xml)
    method_validate
  end

  private

  def schema_validate(xml)
    document = Nokogiri::XML(xml)
    errors = @@schema.validate(document)
    return if errors.empty?
    fail 'Schema validation errors: ' + errors.join("\n")
  end

  def method_validate
    # Warm the object and check for missing data, beyond what the schema enforces.
    errors = []
    (PBCore.instance_methods(false) - [:to_solr]).each do |method|
      begin
        self.send(method)
      rescue => e
        errors << e.message
      end
    end
    return if errors.empty?
    fail 'Method validation errors: ' + errors.join("\n")
  end

end
