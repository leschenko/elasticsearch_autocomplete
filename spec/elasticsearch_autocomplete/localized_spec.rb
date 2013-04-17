require 'spec_helper'

class ActiveModelProductLocalized < StubModelBase
  ac_field :name, :localized => true

  def self.test_data
    [
        {:name_ru => 'name_ru first', :name_en => 'name_en first'},
        {:name_ru => 'name_ru second', :name_en => 'name_en second'}
    ]
  end

  def self.populate
    test_data.each_with_index do |data, id|
      u = new(data)
      u.id = id
      u.save
    end
  end
end

describe 'suggestions for localized attributes' do
  before :all do
    @model = ActiveModelProductLocalized
    @model.setup_index
  end

  it 'don\'t suggest from all locales' do
    @model.ac_search('name_en first').to_a.should have(1).results
    @model.ac_search('name_ru first').to_a.should have(1).results
    @model.ac_search('name_ru').to_a.should have(2).results
  end
end