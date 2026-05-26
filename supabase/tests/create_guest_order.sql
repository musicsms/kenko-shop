select public.create_guest_order(
  'Test Customer',
  '0900000000',
  '123 Test Street',
  'Leave at door',
  '[{"product_slug":"bok-choy","quantity":2}]'::jsonb
) as result;

select count(*) as created_orders
from public.orders
where customer_phone = '0900000000';
