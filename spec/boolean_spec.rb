RSpec.describe Ruson::Base do
  class BooleanObject < Ruson::Base
    field :enabled, class: Boolean
  end

  it 'convert to boolean' do
    obj = BooleanObject.new({ enabled: true })
    expect(obj.enabled).to be_truthy

    obj = BooleanObject.new({ enabled: false })
    expect(obj.enabled).to be_falsey

    obj = BooleanObject.new({ enabled: 'true' })
    expect(obj.enabled).to be_truthy

    obj = BooleanObject.new({ enabled: 'false' })
    expect(obj.enabled).to be_falsey

    obj = BooleanObject.new({ enabled: 'boolean' })
    expect(obj.enabled).to be_falsey
  end
end
