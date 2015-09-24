class Query
  def initialize options, map
    @options = options
    @map = map

    @map.keys.each do |key|
      self.class.send(:define_method, key, Proc.new { @map[key] })
    end
  end

  def not_null_receipts
    sql = <<-SQL
            SELECT receipt_properties
            FROM #{merchant}
            WHERE receipt_properties IS NOT NULL
          SQL
  end

  def non_revenue_payments
    sql = <<-SQL
            SELECT *
            FROM #{line_item}
            WHERE created_time >= "#{@options[:start_time]}"
              AND created_time <= "#{@options[:end_time]}"
              AND refund_id IS NULL
              AND is_revenue = 0
              AND order_id IN (
                SELECT id
                FROM #{orders}
                WHERE merchant_id = #{@options[:merchant_id]}
                AND deleted_timestamp IS NULL
                AND state IS NOT NULL
                AND modified_time >= "#{@options[:start_time]}"
                AND created_time >= "#{@options[:start_time]}"
                AND created_time <= "#{@options[:end_time]}"
              )
          SQL
  end

  def orders_by_merchant
    sql = <<-SQL
            SELECT *
            FROM #{orders}
            WHERE merchant_id = #{@options[:merchant_id]}
            AND deleted_timestamp IS NULL
            AND created_time >= "#{@options[:start_time]}"
            AND created_time <= "#{@options[:end_time]}"
          SQL
  end

  def payment_sql
    sql = <<-SQL
            SELECT  payment.id as payment_id, orders.uuid as order_uuid, payment.amount as payment_amount,
              COALESCE(payment.tax_amount,0) as payment_tax_amount,
              COALESCE(payment.tip_amount,0) as payment_tip_amount,
              payment.merchant_tender_id as payment_merchant_tender_id,
              merchant_tender.label as payment_merchant_tender_label,
              merchant_tender.label_key as payment_merchant_tender_label_key, account.name as employee_name,
              account.uuid as employee_id, gateway_tx.card_type as card_type,
              COALESCE(payment_service_charge.amount,0) as payment_service_charge_amount
            FROM #{payment}
              LEFT OUTER JOIN #{payment_service_charge} ON payment_service_charge.payment_id = payment.id
              LEFT OUTER JOIN #{merchant_tender} ON merchant_tender.id = payment.merchant_tender_id
              LEFT OUTER JOIN #{orders} ON orders.id = payment.order_id
              LEFT OUTER JOIN #{account} on payment.account_id = account.id
              LEFT OUTER JOIN #{gateway_tx} ON payment.gateway_tx_id = gateway_tx.id
            WHERE orders.merchant_id = #{@options[:merchant_id]}
              AND payment.client_created_time >= "#{@options[:start_time]}"
              AND payment.client_created_time <= "#{@options[:end_time]}"
              AND payment.result = 'success'
              AND orders.deleted_timestamp IS NULL
              AND orders.modified_time >= "#{@options[:start_time]}"
              AND payment.payment_refund_id IS NULL
          SQL
  end

  def item_sql
    sql = <<-SQL
      SELECT li.uuid AS id, i.uuid AS item_id, li.unit_price AS price, li.unit_qty AS unit_qty,
      COALESCE(li.name, 'Custom Item') AS name, li.is_revenue AS revenue_item,
      li.exchanged_line_item_id IS NOT NULL AS exchanged, li.refund_id IS NOT NULL AS refunded,
      GROUP_CONCAT(DISTINCT CASE WHEN a.uuid IS NULL THEN NULL ELSE CONCAT_WS(0x1F, COALESCE(a.uuid, ''),
        COALESCE(a.type, ''), COALESCE(a.amount, ''), COALESCE(a.percentage, ''), COALESCE(COALESCE(COALESCE(d.name, a.name),
        'Generic Discount'), '')) END ORDER BY a.uuid SEPARATOR 0x1E)
      AS raw_adjustments, GROUP_CONCAT(CASE WHEN lim.uuid IS NULL THEN NULL ELSE CONCAT_WS(0x1F, COALESCE(lim.uuid, ''),
      COALESCE(lim.amount, ''), COALESCE(lim.name, ''), COALESCE(m.uuid, '')) END ORDER BY lim.uuid SEPARATOR 0x1E) AS raw_modifications
      FROM #{line_item} AS li
      JOIN #{orders} AS o ON (o.id = li.order_id)
      LEFT JOIN #{item} AS i ON (i.id = li.item_id)
      LEFT JOIN #{payment} AS p ON (o.id = p.order_id)
      LEFT JOIN #{adjustment} AS a ON (a.line_item_id = li.id)
      LEFT JOIN #{discount} AS d ON (a.discount_id = d.id)
      LEFT JOIN #{line_item_modification} AS lim ON (lim.line_item_id = li.id)
      LEFT JOIN #{modifier} AS m ON (lim.modifier_id = m.id)
      WHERE o.merchant_id = 1417;
    SQL
  end

  def payments_regular_join
    sql = <<-SQL
            SELECT payment.id as payment_id, orders.uuid as order_uuid, payment.amount as payment_amount,
              COALESCE(payment.tax_amount,0) as payment_tax_amount,
              COALESCE(payment.tip_amount,0) as payment_tip_amount,
              payment.merchant_tender_id as payment_merchant_tender_id,
              merchant_tender.label as payment_merchant_tender_label,
              merchant_tender.label_key as payment_merchant_tender_label_key, account.name as employee_name,
              account.uuid as employee_id, gateway_tx.card_type as card_type,
              COALESCE(payment_service_charge.amount,0) as payment_service_charge_amount
            FROM #{payment}
            LEFT OUTER JOIN #{payment_service_charge} ON payment_service_charge.payment_id = payment.id
            LEFT OUTER JOIN #{merchant_tender} ON merchant_tender.id = payment.merchant_tender_id
            LEFT OUTER JOIN #{orders} ON orders.id = payment.order_id
            LEFT OUTER JOIN #{account} on payment.account_id = account.id
            LEFT OUTER JOIN #{gateway_tx} ON payment.gateway_tx_id = gateway_tx.id
            WHERE orders.merchant_id = #{@options[:merchant_id]}
            AND payment.client_created_time >= "#{@options[:start_time]}"
            AND payment.client_created_time <= "#{@options[:end_time]}"
            AND payment.result = 'success'
            AND orders.deleted_timestamp IS NULL
            AND orders.modified_time >= "#{@options[:start_time]}"
            AND payment.payment_refund_id IS NULL;
          SQL
  end

  def payments_2
    sql = <<-SQL
            SELECT p.merchant_id as merchant_id,
            sum(p.amount) as amount,
            COALESCE(sum(p.tip_amount),0) as tip_amount, COALESCE(sum(p.tax_amount), 0) as tax_amount,
            sum(c.amount) as service_charge_amount, count(*) as num
            FROM #{payment} AS p
            INNER JOIN #{merchant_tender} AS t ON p.merchant_tender_id = t.id
            INNER JOIN #{orders} AS o ON p.order_id = o.id
            LEFT OUTER JOIN #{payment_service_charge} As c on c.payment_id = p.id
            LEFT OUTER JOIN #{account} AS e ON p.account_id = e.id
            LEFT OUTER JOIN #{gateway_tx} AS gtx ON p.gateway_tx_id = gtx.id
            LEFT OUTER JOIN #{device} d ON p.device_id = d.id
            WHERE p.merchant_id = 1417;
        SQL
  end

  def refund_sql
    sql = <<-SQL
            SELECT refund.id as refund_id, payment.id as payment_id, orders.id as order_id,
            refund.amount as refund_amount,
            COALESCE(refund.tax_amount,0) as refund_tax_amount,
            merchant_tender.label as refund_merchant_tender_label,
            merchant_tender.label_key as refund_merchant_tender_label_key, account.name as employee_name,
            account.uuid as employee_id, account.uuid as employee_id,
            COALESCE(refund_service_charge.amount,0) as refund_service_charge_amount
            FROM #{@map["refund"]}
            LEFT OUTER JOIN #{@map["refund_service_charge"]} ON refund_service_charge.refund_id = refund.id
            LEFT OUTER JOIN #{@map["payment"]} ON refund.payment_id = payment.id
            LEFT OUTER JOIN #{@map["merchant_tender"]} ON merchant_tender.id = payment.merchant_tender_id
            LEFT OUTER JOIN #{@map["orders"]} ON orders.id = payment.order_id
            LEFT OUTER JOIN #{@map["account"]} on refund.account_id = account.id
            WHERE orders.merchant_id = #{@options[:merchant_id]}
            AND payment.client_created_time >= "#{@options[:start_time]}"
            AND refund.client_created_time <= "#{@options[:end_time]}"
            AND orders.deleted_timestamp IS NULL
            AND orders.modified_time >= "#{@options[:start_time]}"
        SQL
  end

  def credit_sql
    sql = <<-SQL
          SELECT credit.id as credit_id, orders.uuid as order_uuid, credit.amount as credit_amount,
          COALESCE(credit.tax_amount,0) as credit_tax_amount,
          merchant_tender.label as credit_merchant_tender_label,
          merchant_tender.label_key as credit_merchant_tender_label_key, account.name as employee_name,
          account.uuid as employee_id, gateway_tx.card_type as card_type\
          FROM #{@map["credit"]}
          LEFT OUTER JOIN #{@map["merchant_tender"]} ON merchant_tender.id = credit.merchant_tender_id
          LEFT OUTER JOIN #{@map["orders"]} ON orders.id = credit.order_id
          LEFT OUTER JOIN #{@map["account"]} on credit.account_id = account.id
          LEFT OUTER JOIN #{@map["gateway_tx"]} ON credit.gateway_tx_id= gateway_tx.id
          WHERE orders.merchant_id = #{@options[:merchant_id]}
          AND credit.client_created_time >= "#{@options[:start_time]}"
          AND credit.client_created_time <= "#{@options[:end_time]}"
          AND orders.deleted_timestamp IS NULL
          AND orders.modified_time >= "#{@options[:start_time]}"
        SQL
  end

  def cash
    sql = <<-SQL
            SELECT event.type, event.amount_change, device.uuid as device, merchant_device.name as device_name
            FROM cash_event_log event
            FORCE INDEX (device_id_timestamp)
            LEFT OUTER JOIN #{@map["account"]} ON account.id = event.account_id
            LEFT OUTER JOIN #{@map["merchant_role"]} ON (merchant_role.account_id=account.id AND merchant_role.merchant_id=#{@options[:merchant_id]})
            LEFT OUTER JOIN #{@map["device"]} ON (device.id = event.device_id)
            LEFT OUTER JOIN #{@map["merchant_device"]} ON (merchant_device.device_id = device.id)
            LEFT OUTER JOIN #{@map["authtoken"]} ON (authtoken.device_id = device.id AND authtoken.merchant_id = #{@options[:merchant_id]})
            WHERE merchant_role.merchant_id = #{@options[:merchant_id]}
            AND authtoken.id IS NOT NULL
            AND event.timestamp >= "#{@options[:start_time]}"
            AND event.timestamp <= "#{@options[:end_time]}"
          SQL
  end

  def orders (order_list)
    order_list = order_list.map{|el| "'#{el}'"}
    sql = <<-SQL
            SELECT *
            FROM orders
            WHERE uuid in (#{order_list.join(', ')})
          SQL
  end

  def line_item_income
    sql = <<-SQL
      SELECT sum(unit_price)
      FROM line_item
      WHERE line_item.created_time >= ?
      AND line_item.created_time <= ?
        (SELECT id
          FROM orders
          WHERE merchant_id = ?
          AND orders.deleted_timestamp IS NULL
          AND orders.modified time >= ?)
      SQL
  end

end
