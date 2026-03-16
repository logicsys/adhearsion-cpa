require 'spec_helper'

RSpec.describe AdhearsionCpa::ControllerMethods do

    let(:mock_call) { Adhearsion::Call.new }
    subject { Adhearsion::CallController.new mock_call }

    let(:mock_complete_event) { double Punchblock::Event::Complete, reason: mock_signal   }
    let(:mock_signal)         { double Punchblock::Component::Input::Signal, type: "dtmf" }

    describe "#detect_tone" do
      context "when watching for a beep" do
        let(:mock_signal)         { double 'Signal', type: "beep" }

        it "detects a beep" do
          expect(mock_call).to receive(:write_and_await_response).with(an_instance_of(Punchblock::Component::Input))
          expect_any_instance_of(Punchblock::Component::Input).to receive(:complete_event).and_return(mock_complete_event)

          expect(subject.detect_tone(:beep, timeout: 5).type).to eq("beep")
        end
      end

      context "when watching for a beep and modem" do
        let(:mock_signal) { double 'Signal', type: :beep }

        it "detects which tone" do
          expect(mock_call).to receive(:write_and_await_response).with(an_instance_of(Punchblock::Component::Input)).and_return(mock_signal)
          expect_any_instance_of(Punchblock::Component::Input).to receive(:complete_event).and_return(mock_complete_event)

          expect(subject.detect_tone(:beep, :modem, timeout: 5).type).to eq(:beep)
        end
      end

      context "when timing out" do
        it "returns nil" do
          expect(mock_call).to receive(:write_and_await_response).with(an_instance_of(Punchblock::Component::Input)).and_raise(Timeout::Error)
          expect_any_instance_of(Punchblock::Component::Input).to receive(:executing?).and_return(true)
          expect_any_instance_of(Punchblock::Component::Input).to receive(:stop!)

          expect(subject.detect_tone(:beep, timeout: 5)).to be_nil
        end
      end

      context "with an options hash" do
        it "encodes them in the grammar URL" do
          expect(mock_call).to receive(:write_and_await_response).with(an_instance_of(Punchblock::Component::Input))
          expect_any_instance_of(Punchblock::Component::Input).to receive(:complete_event).and_return(mock_complete_event)

          subject.detect_tone :speech, maxTime: 4000, minSpeechDuration: 4000, timeout: 5
        end
      end

      context "with individual options, and an options hash" do
        it "encodes the individual and group options in the grammar URL" do
          expect(mock_call).to receive(:write_and_await_response).with(an_instance_of(Punchblock::Component::Input))
          expect_any_instance_of(Punchblock::Component::Input).to receive(:complete_event).and_return(mock_complete_event)

          subject.detect_tone({speech: {maxTime: 4000, minSpeechDuration: 4000}, beep: {}}, timeout: 5, foo: :bar)
        end
      end
    end

    describe "#detect_tone!" do
      let(:mock_component) { double Punchblock::Component::Input, executing?: true }

      before do
        expect(Punchblock::Component::Input).to receive(:new).
          with(mode: :cpa, grammars: expected_grammars).
          and_return(mock_component)

        expect(mock_component).to receive(:register_event_handler).with(Punchblock::Component::Input::Signal) do |&block|
          @on_detect_signal_block = block
        end
        expect(mock_component).to receive(:register_event_handler).with(Punchblock::Event::Complete) do |&block|
          @on_detect_complete_block = block
        end

        expect(mock_call).to receive(:write_and_await_response).with(mock_component)
      end

      context "with :terminate set to true" do
        let(:expected_grammars) do
          [ Punchblock::Component::Input::Grammar.new(url: "urn:xmpp:rayo:cpa:dtmf:1?terminate=true") ]
        end

        it "detects the dtmf" do
          detector = subject.detect_tone!(:dtmf, timeout: 0.02) { |tone| tone.type }
          expect(detector).to eq(mock_component)
          expect(mock_signal).to receive(:is_a?).with(Punchblock::Component::Input::Signal).and_return(true)
          expect(mock_signal).to receive(:type)
          @on_detect_complete_block.call mock_complete_event

          expect(mock_component).to receive(:stop!)
          sleep 0.04
        end
      end

      context "with :terminate set to false" do
        let(:expected_grammars) do
          [ Punchblock::Component::Input::Grammar.new(url: "urn:xmpp:rayo:cpa:dtmf:1") ]
        end

        it "watches repeatedly in the background" do
          detector = subject.detect_tone!(:dtmf, timeout: 0.02, terminate: false) { |tone| tone.type }
          expect(detector).to eq(mock_component)

          expect(mock_signal).to receive(:type).twice
          @on_detect_signal_block.call mock_signal
          @on_detect_signal_block.call mock_signal

          expect(mock_component).to receive(:stop!)
          sleep 0.1
        end

        context "without a timeout" do
          it "doesn't ever stop.." do
            detector = subject.detect_tone!(:dtmf, terminate: false) { |tone| tone.type }
            expect(detector).to eq(mock_component)

            expect(mock_signal).to receive(:type).twice
            @on_detect_signal_block.call mock_signal
            @on_detect_signal_block.call mock_signal

            expect(mock_component).not_to receive(:stop!)
            sleep 0.04
          end
        end
      end
    end
end
