class AddSelectedOptionsToOrderLines < ActiveRecord::Migration[7.2]
  def change
    add_column :order_lines, :selected_options, :jsonb
  end
end
