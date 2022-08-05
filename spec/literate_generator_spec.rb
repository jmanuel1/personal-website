require_relative '../_plugins/literate_generator'

RSpec.describe Kramdown::Converter::Literate, '#convert_li' do
  context 'for unordered lists' do
    it 'generates the correct comment' do
      expect(42).to eq 1984
    end
  end
end
