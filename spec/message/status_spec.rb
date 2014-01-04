require 'spec_helper'

describe Coin2Coin::Message::Status do
  before do
    fake_all_network_connections
  end

  before do
    if !transaction_id.nil?
      Coin2Coin::Bitcoin.instance.test_add_transaction_id_to_pool(transaction_id)
      Coin2Coin::Bitcoin.instance.test_confirm_block
    end
  end

  let(:default_message) { build(:status_message) }
  let(:status) { default_message.status }
  let(:transaction_id) { default_message.transaction_id }
  let(:current_block_height) { default_message.updated_at[:block_height] }
  let(:current_nonce) { default_message.updated_at[:nonce] }
  let(:updated_at) { default_message.updated_at }
  let(:coin_join) { default_message.coin_join }

  describe "validations" do
    let(:message) do
      build(:status_message,
        status: status,
        transaction_id: transaction_id,
        updated_at: updated_at)
    end

    subject { message.valid? }

    it "is valid with default data" do
      subject
      expect(subject).to be_true
    end

    describe "transaction_id" do
      context "when present" do
        Coin2Coin::Message::Status::STATUSES_REQUIRING_TRANSACTION_ID.each do |test_status|
          context "with #{test_status} status" do
            let(:status) { test_status }

            it "is valid" do
              expect(subject).to be_true
            end
          end
        end

        (Coin2Coin::StateMachine::Controller::STATUSES - Coin2Coin::Message::Status::STATUSES_REQUIRING_TRANSACTION_ID).each do |test_status|
          context "with #{test_status} status" do
            let(:status) { test_status }

            it "is invalid" do
              expect(subject).to be_false
              expect(message.errors[:transaction_id]).to include("must not be present for status #{test_status}")
            end
          end
        end
      end

      context "when nil" do
        let(:transaction_id) { nil }

        Coin2Coin::Message::Status::STATUSES_REQUIRING_TRANSACTION_ID.each do |test_status|
          context "with #{test_status} status" do
            let(:status) { test_status }

            it "is invalid" do
              expect(subject).to be_false
              expect(message.errors[:transaction_id]).to include("must be present for status #{test_status}")
            end
          end
        end

        (Coin2Coin::StateMachine::Controller::STATUSES - Coin2Coin::Message::Status::STATUSES_REQUIRING_TRANSACTION_ID).each do |test_status|
          context "with #{test_status} status" do
            let(:status) { test_status }

            it "is valid" do
              expect(subject).to be_true
            end
          end
        end
      end
    end

    describe "transaction_confirmed" do
      context "when in Complete state" do
        let(:status) { 'Complete' }

        context "with confirmed transaction" do
          it "is valid" do
            expect(subject).to be_true
          end
        end

        context "with no confirmed transaction" do
          let(:transaction_id) { nil }

          it "is invalid" do
            expect(subject).to be_false
            expect(message.errors[:transaction_id]).to include("is not confirmed")
          end
        end
      end
    end

    describe "status_valid" do
      context "when status is invalid" do
        let(:status) { 'InvalidStatus' }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:status]).to include("is not a valid status")
        end
      end
    end

    describe "updated_at" do
      context "with non-Hash" do
        let(:updated_at) { nil }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:updated_at]).to include("must be a hash")
        end
      end

      context "with non-existant block height" do
        let(:updated_at) { { :block_height => current_block_height + 1, :nonce => current_nonce } }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:updated_at]).to include("is not a valid block")
        end
      end

      context "with invalid nonce" do
        let(:updated_at) { { :block_height => current_block_height, :nonce => "wrong nonce" } }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:updated_at]).to include("is not a valid block")
        end
      end
    end
  end

  describe "build" do
    subject { Coin2Coin::Message::Status.build(coin_join, status, transaction_id) }

    it "builds valid input" do
      input = subject
      expect(input.valid?).to be_true
    end
  end

  describe "from_json" do
    let(:message) { default_message }
    let(:json) do
      {
        status: message.status,
        transaction_id: message.transaction_id,
        updated_at: message.updated_at
      }.to_json
    end

    subject do
      Coin2Coin::Message::Status.from_json(json, coin_join)
    end

    it "creates a valid input" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.status).to eq(message.status)
      expect(subject.transaction_id).to eq(message.transaction_id)
      expect(subject.updated_at).to eq(message.updated_at)
    end
  end
  
end