require_relative File.expand_path('libraries/canaria')
require 'rspec'

describe Canaria do
  describe '.canary?' do
    # 1000 fake random nodes
    let(:nodes) do
      @nodes ||= begin
        nodes = []
        250.times do
          %w(west east dublin singapore).each do |region|
            nodes << "node-#{Random.new(1000)}-#{region}.test.com"
          end
        end
        nodes
      end
    end

    (1..99).each do |percent|
      context "When the Canary % is set to #{percent}" do
        it "successfully determines canaries withing 5% of #{percent}" do
          canary_count = nodes.inject(0) do |count, node|
            described_class.canary?(node, percent) ? count + 1 : count
          end

          expect(canary_count).to be_within(50).of(percent * 10)
        end
      end
    end

    [0, 100].each do |percent|
      context "When the Canary % is set to #{percent}" do
        it 'successfully determines the exact number of canaries' do
          canary_count = nodes.inject(0) do |count, node|
            described_class.canary?(node, percent) ? count + 1 : count
          end

          expect(canary_count).to eq(percent * 10)
        end
      end
    end

    context 'when overrides are given' do
      let(:node) { 'node-01-dublin.test.com' }
      let(:overrides) do
        nodes = []
        (1..9).each do |i|
          nodes << "node-0#{i}-dublin.test.com"
        end
        nodes
      end

      context 'when a node is in the overrides' do
        context 'when the percent is zero' do
          it 'correctly determines that it is a canary' do
            expect(described_class.canary?(node, 0, overrides)).to eq(true)
          end
        end

        context 'when the percent is non-zero' do
          it 'correctly determines that it is a canary' do
            expect(described_class.canary?(node, 5, overrides)).to eq(true)
          end
        end
      end

      context 'when a node is not the overrides' do
        let(:node) { 'node-01-singapore.test.com' }

        context 'when the percent is zero' do
          it 'correctly determines that it is a canary' do
            expect(described_class.canary?(node, 0, overrides)).to eq(false)
          end
        end
      end
    end
  end
end
