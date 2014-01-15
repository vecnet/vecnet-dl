require 'spec_helper'

describe 'inflections' do
  it 'plural of "thesis" is "theses"' do
    "thesis".pluralize.should == 'theses'
  end
  it 'singular of "theses" is "thesis"' do
    "theses".singularize.should == 'thesis'
  end

  it '"generic_file" should classify to GenericFile' do
    "generic_file".classify.should == "GenericFile"
  end

  it '"generic_files" should classify to GenericFile' do
    "generic_files".classify.should == "GenericFile"
  end
end