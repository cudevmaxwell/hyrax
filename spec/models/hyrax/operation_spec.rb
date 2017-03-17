require 'spec_helper'

describe Hyrax::Operation do
  describe "#rollup_status" do
    let(:parent) { create(:operation, :pending) }
    describe "with a pending process" do
      let!(:child1) { create(:operation, :failing, parent: parent) }
      let!(:child2) { create(:operation, :pending, parent: parent) }
      it "sets status to pending" do
        parent.rollup_status
        expect(parent.status).to eq Hyrax::Operation::PENDING
      end
    end

    describe "with only failing processes" do
      let(:grandparent) { create(:operation, :pending) }
      let(:parent) { create(:operation, :pending, parent: grandparent) }
      let!(:child1) { create(:operation, :failing, parent: parent) }
      it "sets status to fail and roll_up to the parent" do
        # Without this line the `expect(grandparent).to receive(:fail!)` fails
        allow(parent).to receive(:parent).and_return(grandparent)
        expect(grandparent).to receive(:fail!)
        parent.rollup_status
        expect(parent.status).to eq Hyrax::Operation::FAILURE
      end
    end

    describe "with a failure" do
      let!(:child1) { create(:operation, :failing, parent: parent) }
      let!(:child2) { create(:operation, :successful, parent: parent) }
      it "sets status to failure" do
        parent.rollup_status
        expect(parent.status).to eq Hyrax::Operation::FAILURE
      end
    end

    describe "with a successes" do
      let!(:child1) { create(:operation, :successful, parent: parent) }
      let!(:child2) { create(:operation, :successful, parent: parent) }
      it "sets status to success" do
        parent.rollup_status
        expect(parent.status).to eq Hyrax::Operation::SUCCESS
      end
    end
  end

  describe "performing!" do
    it "changes the status to performing" do
      subject.performing!
      expect(subject.status).to eq Hyrax::Operation::PERFORMING
    end
  end

  describe "success!" do
    subject { create(:operation, :pending, parent: parent) }
    let(:parent) { create(:operation, :pending) }
    it "changes the status to SUCCESS and rolls the status up to the parent" do
      # Without this line the `expect(parent).to receive(:rollup_status)` fails
      allow(subject).to receive(:parent).and_return(parent)
      expect(parent).to receive(:rollup_status)
      subject.success!
      expect(subject.status).to eq Hyrax::Operation::SUCCESS
    end
  end

  describe "fail!" do
    subject { create(:operation, :pending, parent: parent) }
    let(:parent) { create(:operation, :pending) }
    it "changes the status to FAILURE and rolls the status up to the parent" do
      # Without this line the `expect(parent).to receive(:rollup_status)` fails
      allow(subject).to receive(:parent).and_return(parent)
      expect(parent).to receive(:rollup_status)
      subject.fail!
      expect(subject.status).to eq Hyrax::Operation::FAILURE
    end
  end
end
