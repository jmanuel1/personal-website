require 'approvals/rspec'
require_relative '../_plugins/literate_generator'

RSpec.describe Kramdown::Converter::Literate, '#convert_li' do
  context 'for unordered lists' do
    it 'generates the correct comment' do
      verify do
        'this is the the thing you want to verify'
      end
    end
  end
end
