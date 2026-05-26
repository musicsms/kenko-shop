insert into public.products (
  id,
  slug,
  name,
  category,
  price,
  unit,
  origin_name,
  origin_region,
  origin_story,
  harvest_label,
  soil_score,
  caption,
  is_limited_drop,
  drop_ends_at,
  palette_background,
  palette_primary,
  palette_secondary,
  palette_accent
) values
('11111111-1111-4111-8111-111111111111', 'bok-choy', 'Da Lat Baby Bok Choy', 'Greens', 42000, '300g', 'Moc Chau Morning Farm', 'Da Lat Highlands', 'Cut before sunrise and packed in reusable cold crates.', 'Harvested 06:10', 96, 'Crisp stems, sweet leaf, perfect for garlic stir-fry.', true, now() + interval '8 hours', '#101510', '#7FBF66', '#DCEB99', '#F2C35B'),
('22222222-2222-4222-8222-222222222222', 'dragon-fruit', 'Red Dragon Fruit', 'Fruit', 68000, '2 pcs', 'Binh Thuan Sun Field', 'Binh Thuan', 'Naturally ripened on the plant with no wax coating.', 'Harvested yesterday', 91, 'Cold, bright, and built for smoothie bowls.', false, null, '#1B1116', '#FF5C7A', '#FFD1DC', '#74C365'),
('33333333-3333-4333-8333-333333333333', 'golden-carrot', 'Golden Soil Carrot', 'Roots', 55000, '500g', 'Red Earth Co-op', 'Don Duong', 'Grown in mineral-rich red soil and washed by hand.', 'Pulled 09:25', 94, 'Snack sweet, soup ready, kid approved.', true, now() + interval '6 hours', '#17120E', '#E69035', '#FFD88A', '#6FA65F'),
('44444444-4444-4444-8444-444444444444', 'purple-basil', 'Purple Basil Bunch', 'Herbs', 28000, '80g', 'An Nhien Herb Garden', 'Gia Lam', 'Small-batch herb beds watered before dawn.', 'Cut 05:50', 89, 'Aromatic lift for salads, noodles, and grilled veg.', false, null, '#151019', '#8E5AC7', '#CDA8FF', '#7FBF66'),
('55555555-5555-4555-8555-555555555555', 'king-oyster', 'King Oyster Mushroom', 'Mushrooms', 72000, '250g', 'North Cloud Grow House', 'Sa Pa', 'Slow-grown in a cool controlled room for dense texture.', 'Picked 07:40', 92, 'Meaty slices for pan sear, broth, or vegan steak.', false, null, '#121417', '#D9C7A3', '#F3E7CE', '#9AC46A'),
('66666666-6666-4666-8666-666666666666', 'organic-box', 'Surprise Organic Box', 'Box', 189000, '6 items', 'Kenko Curated Farms', 'Rotating farms', 'A daily box built from the best harvest window.', 'Packed today', 95, 'Limited fresh drop for cooks who like surprises.', true, now() + interval '10 hours', '#16120B', '#FF6048', '#F2C35B', '#6FA65F')
on conflict (slug) do update set
  name = excluded.name,
  category = excluded.category,
  price = excluded.price,
  unit = excluded.unit,
  origin_name = excluded.origin_name,
  origin_region = excluded.origin_region,
  origin_story = excluded.origin_story,
  harvest_label = excluded.harvest_label,
  soil_score = excluded.soil_score,
  caption = excluded.caption,
  is_limited_drop = excluded.is_limited_drop,
  drop_ends_at = excluded.drop_ends_at,
  palette_background = excluded.palette_background,
  palette_primary = excluded.palette_primary,
  palette_secondary = excluded.palette_secondary,
  palette_accent = excluded.palette_accent,
  updated_at = now();

delete from public.product_nutrition_tags
where product_id in (
  select id
  from public.products
  where slug in (
    'bok-choy',
    'dragon-fruit',
    'golden-carrot',
    'purple-basil',
    'king-oyster',
    'organic-box'
  )
);

insert into public.product_nutrition_tags (product_id, label, value, sort_order)
select products.id, tags.label, tags.value, tags.sort_order
from (
  values
    ('bok-choy', 'Fiber', 'High', 1),
    ('bok-choy', 'Vitamin K', 'Rich', 2),
    ('dragon-fruit', 'Antioxidants', 'Bright', 1),
    ('dragon-fruit', 'Sugar', 'Natural', 2),
    ('golden-carrot', 'Beta carotene', 'High', 1),
    ('golden-carrot', 'Crunch', 'Firm', 2),
    ('purple-basil', 'Aroma', 'Strong', 1),
    ('purple-basil', 'Polyphenols', 'Good', 2),
    ('king-oyster', 'Protein', 'Plant', 1),
    ('king-oyster', 'Umami', 'Deep', 2),
    ('organic-box', 'Variety', '6 picks', 1),
    ('organic-box', 'Waste', 'Low', 2)
) as tags(slug, label, value, sort_order)
join public.products on products.slug = tags.slug;

delete from public.product_bundles
where product_id in (
  select id
  from public.products
  where slug in (
    'bok-choy',
    'dragon-fruit',
    'golden-carrot',
    'purple-basil',
    'king-oyster',
    'organic-box'
  )
);

insert into public.product_bundles (product_id, related_product_id, sort_order)
select products.id, related_products.id, bundles.sort_order
from (
  values
    ('bok-choy', 'king-oyster', 1),
    ('bok-choy', 'purple-basil', 2),
    ('dragon-fruit', 'organic-box', 1),
    ('golden-carrot', 'purple-basil', 1),
    ('golden-carrot', 'organic-box', 2),
    ('purple-basil', 'bok-choy', 1),
    ('purple-basil', 'king-oyster', 2),
    ('king-oyster', 'bok-choy', 1),
    ('king-oyster', 'golden-carrot', 2),
    ('organic-box', 'bok-choy', 1),
    ('organic-box', 'dragon-fruit', 2),
    ('organic-box', 'golden-carrot', 3)
) as bundles(slug, related_slug, sort_order)
join public.products on products.slug = bundles.slug
join public.products related_products on related_products.slug = bundles.related_slug;
