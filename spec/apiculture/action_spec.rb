require_relative '../spec_helper'

describe Apiculture::Action do
  context '.new' do
    it 'exposes the methods of the object given as a first argument to initialize' do
      action_class = Class.new(described_class)
      fake_sinatra = double('Sinatra::Base', something: 'value')
      action = action_class.new(fake_sinatra)
      expect(action).to respond_to(:something)
      expect(action.something).to eq('value')
    end
    
    it 'converts keyword arguments to instance variables' do
      action_class = Class.new(described_class)
      action = action_class.new(nil, foo: 'a string')
      expect(action.instance_variable_get('@foo')).to eq('a string')
    end
  end
  
  it 'responds to perform()' do
    expect(described_class.new(nil)).to respond_to(:perform)
  end
  
  it 'can use bail() to throw a Sinatra halt' do
    fake_sinatra = double('Sinatra::Base')
    expect(fake_sinatra).to receive(:json_halt).with('Failure', status: 400) 
    action_class = Class.new(described_class)
    action_class.new(fake_sinatra).bail "Failure"
  end
  
  it 'can use bail() to throw a Sinatra halt with a custom status' do
    fake_sinatra = double('Sinatra::Base')
    expect(fake_sinatra).to receive(:json_halt).with("Failure", status: 417)
    
    action_class = Class.new(described_class)
    action_class.new(fake_sinatra).bail "Failure", status: 417
  end
  
  it 'can use bail() to throw a Sinatra halt with extra JSON attributes' do
    fake_sinatra = double('Sinatra::Base')
    expect(fake_sinatra).to receive(:json_halt).with("Failure", status: 417, message: "Totale")
    action_class = Class.new(described_class)
    action_class.new(fake_sinatra).bail "Failure", status: 417, message: 'Totale'
  end
end
