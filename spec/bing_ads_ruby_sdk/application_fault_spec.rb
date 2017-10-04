# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BingAdsRubySdk::Errors::ApplicationFault do
  describe '#fault_hash' do
    context 'when creating an instance' do
      subject(:create_instance) { described_class.new({ details: nil }) }

      it 'should instantiate without raising an exception' do
        expect { create_instance }.not_to raise_error
      end
    end
  end
end