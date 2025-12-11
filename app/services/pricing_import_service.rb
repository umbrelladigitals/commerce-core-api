require 'csv'

class PricingImportService
  def initialize(file)
    @file = file
    @results = {
      success_count: 0,
      error_count: 0,
      errors: []
    }
  end

  def process
    # Detect file type
    ext = File.extname(@file.original_filename).downcase
    
    case ext
    when '.csv'
      process_csv
    when '.xlsx', '.xls'
      @results[:error_count] += 1
      @results[:errors] << "Excel dosyaları için 'roo' gem'i gerekli. Lütfen CSV formatı kullanın."
    else
      @results[:error_count] += 1
      @results[:errors] << "Desteklenmeyen dosya formatı: #{ext}"
    end

    @results
  end

  private

  def process_csv
    # Read CSV with headers
    # Handle BOM if present
    content = File.read(@file.path, encoding: 'bom|utf-8')
    csv = CSV.parse(content, headers: true)

    csv.each_with_index do |row, index|
      process_row(row, index + 2) # +2 because index is 0-based and header is row 1
    end
  rescue CSV::MalformedCSVError => e
    @results[:error_count] += 1
    @results[:errors] << "CSV dosyası okunamadı: #{e.message}"
  end

  def process_row(row, row_number)
    sku = row['sku']&.strip
    price = row['price']&.strip

    if sku.blank?
      @results[:error_count] += 1
      @results[:errors] << "Satır #{row_number}: SKU eksik"
      return
    end

    if price.blank?
      @results[:error_count] += 1
      @results[:errors] << "Satır #{row_number}: SKU #{sku} için fiyat eksik"
      return
    end

    # Convert price to cents
    # Assuming price is like "99.99" or "99,99"
    price_clean = price.to_s.gsub(',', '.')
    price_cents = (price_clean.to_f * 100).to_i

    # Try to find Product first
    product = Catalog::Product.find_by(sku: sku)
    
    if product
      update_record(product, price_cents, sku)
    else
      # Try to find Variant
      variant = Catalog::Variant.find_by(sku: sku)
      if variant
        update_record(variant, price_cents, sku)
      else
        @results[:error_count] += 1
        @results[:errors] << "SKU #{sku}: Ürün veya varyant bulunamadı"
      end
    end
  end

  def update_record(record, price_cents, sku)
    if record.update(price_cents: price_cents)
      @results[:success_count] += 1
    else
      @results[:error_count] += 1
      @results[:errors] << "SKU #{sku}: #{record.errors.full_messages.join(', ')}"
    end
  end
end
