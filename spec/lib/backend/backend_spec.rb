require 'spec_helper'

describe Backend do
  describe 'carries reasonable defaults' do
    before do
      Backend.reset
    end
    
    subject{ Backend.configuration }
    
    its(:backend_implementation){ should_not eql(nil) }
    its(:queue_periodicity){ should == 5.minutes }
    its(:queue_quantity){ should eql(30) }
  end
  
  describe 'the SRG configuration works' do
    before do
      Backend.configure do |config|
        config.queue_periodicity = 5.minutes
        config.queue_quantity = 30
        config.backend_implementation.flux_active_limit = 120
        if !Rails.env.test?
          config.backend_implementation.setup_connections
        end
      end
    end
    
    subject{ Backend.configuration.backend_implementation }
    
    its(:class){ should eql(FluxBackend) }
    its(:flux_active_limit){ should eql(120) }
  end
  
  describe 'API' do
    before do
      Backend.reset
    end
    
    let(:simulation){ double('simulation') }
    
    [:prepare_simulation, :update_simulation, :schedule_simulation].each do |method|
      describe method do
        it 'passes the message along to the backend implementation' do
          Backend.configuration.backend_implementation.should_receive(method).with(simulation)
          Backend.send method, simulation
        end
      end
    end
    
    describe 'prepare_simulator' do
      let(:simulator){ double('simulator') }
      
      it 'passes the message along to the backend implementation' do
        Backend.configuration.backend_implementation.should_receive(:prepare_simulator).with(simulator)
        Backend.prepare_simulator(simulator)
      end
    end
  end
  
  describe "Configuration" do
    subject{ Backend::Configuration.new }
    its(:backend_implementation){ subject.class.should eql(FluxBackend) }
    its(:queue_periodicity){ should == 5.minutes }
    its(:queue_quantity){ should eql(30) }
  end
end