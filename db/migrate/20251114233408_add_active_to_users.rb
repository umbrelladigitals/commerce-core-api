class AddActiveToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :active, :boolean, default: true, null: false
    
    # Tüm mevcut kullanıcıları aktif yap
    reversible do |dir|
      dir.up do
        User.update_all(active: true)
      end
    end
  end
end
