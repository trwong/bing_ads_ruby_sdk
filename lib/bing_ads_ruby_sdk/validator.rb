# frozen_string_literal: true

require "nokogiri"
require "forwardable"

module BingAdsRubySdk
  # Validates the next to be sent SOAP request with XSD files extracted from the official WSDL file
  class Validator
    extend Forwardable

    # Requests that should not be validated (recurrent or inexistant in official XSD files)
    WHITE_LIST = %w(SignupCustomerRequest).freeze

    # Validates request's body. Halts execution if any error is found and write warnings into logs
    def validate(req)
      body = body(req)

      return if WHITE_LIST.include?(body.name)

      output(
        schema.validate(Nokogiri::XML(body.to_xml))
      )
    end

    private

    # Extracts the Body part of the SOAP:ENVELOPE XML request. Move namespace attributes from the envelope to the
    # extracted XML part
    def body(req)
      root = Nokogiri::XML(req.content).root

      root.children
        .find { |e| e.name == "Body" }.children
        .find { |e| e.name != "text" }
        .tap do |body|
        root.namespaces.each do |k, v|
          body.set_attribute k, v
        end
      end
    end

    # Handles errors and warnings differently
    def output(messages)
      errors, warnings = messages.partition{ |e| e.message.include?("ERROR:") }

      BingAdsRubySdk.logger.debug("[XSD Validations] Warnings: #{warnings.inspect}") if warnings.any?
      raise ArgumentError, "[XSD Validations] Errors: #{errors.inspect}" if errors.any?
    end

    def_delegator self, :schema

    class << self
      def validate(*args)
        new.validate(*args)
      end

      # Loading schema files is time consuming. Better memoize the validator at the class Level
      def schema
        @schema ||= Nokogiri::XML::Schema.new(schema_file)
      end

      # Navigates to the XSD files location from the current script file location
      def schema_file
        path_parts = __FILE__.split("/")

        File.open(
          (path_parts[0...(path_parts.size - 3)] + ["vendor", "xsd", "main.xsd"]).join("/")
        )
      end
    end
  end
end
