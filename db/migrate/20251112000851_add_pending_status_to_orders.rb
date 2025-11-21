class AddPendingStatusToOrders < ActiveRecord::Migration[7.2]
  def up
    # Yeni pending statüsü için enum değeri ekle
    # Mevcut enum değerleri: cart: 0, paid: 1, shipped: 2, cancelled: 3
    # Yeni değer: pending: 4
    
    # Not: Enum değerleri integer olduğu için direkt SQL kullanıyoruz
    # pending statüsü sipariş alındı ama ödeme bekleniyor durumu için
  end
  
  def down
    # Geri alma işlemi - pending statüsündeki siparişleri cart'a çevir
    execute "UPDATE orders SET status = 0 WHERE status = 4"
  end
end
