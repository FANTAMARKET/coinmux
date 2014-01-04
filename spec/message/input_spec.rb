require 'spec_helper'
require 'base64'

describe Coin2Coin::Message::Input do
  before do
    fake_all_network_connections
  end

  let(:default_message) { build(:input_message) }
  let(:input_identifier) { default_message.input_identifier }
  let(:address) { default_message.address }
  let(:private_key) { default_message.private_key }
  let(:signature) { default_message.signature }
  let(:change_address) { default_message.change_address }
  let(:coin_join) { default_message.coin_join }
  
  describe "validations" do
    let(:message) do
      build(:input_message,
        address: address,
        private_key: private_key,
        signature: signature,
        change_address: change_address,
        coin_join: coin_join)
    end

    subject { message.valid? }

    it "is valid with default data" do
      subject
      expect(subject).to be_true
    end

    describe "signature_correct" do
      context "with invalid signature" do
        let(:signature) { Base64.encode64('invalid').strip }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:signature]).to include("is not correct for address #{address}")
        end
      end
    end

    describe "change_address_valid" do
      context "with invalid change address" do
        let(:change_address) { "invalid_address" }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:change_address]).to include("is not a valid address")
        end
      end
    end
  end

  describe "build" do
    subject { Coin2Coin::Message::Input.build(coin_join, private_key) }

    it "builds valid input" do
      expect(subject.valid?).to be_true
    end

    it "has private_key" do
      expect(subject.private_key).to eq(private_key)
    end

    it "has message_private_key and message_public_key for encrypting and decrypting" do
      message = "a random message #{rand}"
      encrypted_message = Coin2Coin::PKI.instance.private_encrypt(subject.message_private_key, message)
      expect(Coin2Coin::PKI.instance.public_decrypt(subject.message_public_key, encrypted_message)).to eq(message)
    end
  end

  describe "from_json" do
    let(:message) { default_message }
    let(:json) do
      {
        message_public_key: message.message_public_key,
        address: message.address,
        change_address: message.change_address,
        signature: message.signature
      }.to_json
    end

    subject do
      Coin2Coin::Message::Input.from_json(json, coin_join)
    end

    it "creates a valid input" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.message_public_key).to eq(message.message_public_key)
      expect(subject.address).to eq(message.address)
      expect(subject.change_address).to eq(message.change_address)
    end
  end
  
end
