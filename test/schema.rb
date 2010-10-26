ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string :name
    t.string :country_code
    t.date :created_at
  end
  
  create_table :legacy_users, :force => true, :primary_key => :legacy_id do |t|
    t.string :name
    t.string :country_code
    t.date :created_at
  end
end