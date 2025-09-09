# FreshK Seeder Data

This document explains how to use the seed data for the FreshK application.

## Overview

The seed data includes:
- Users (admins, retailers, suppliers)
- Product categories and products
- Shopping carts
- Orders and order items
- Payment transactions
- Inventory logs
- Analytics data

## Loading the Seed Data

To load all the seed data at once, run:

```bash
chmod +x load_seed_data.sh
./load_seed_data.sh
```

This script will:
1. Generate hashed passwords for the users
2. Load all fixture data in the correct order

## User Credentials

After running the script, you can log in with the following credentials:

### Admin Users
- Username: `admin1`, Password: `admin1`
- Username: `admin2`, Password: `admin2`
- Username: `admin3`, Password: `admin3`

### Retailer Users
- Username: `retailer1`, Password: `retailer1`
- Username: `retailer2`, Password: `retailer2`
- Username: `retailer3`, Password: `retailer3`
- Username: `retailer4`, Password: `retailer4`
- Username: `retailer5`, Password: `retailer5`

### Supplier Users
- Username: `supplier1`, Password: `supplier1`
- Username: `supplier2`, Password: `supplier2`
- Username: `supplier3`, Password: `supplier3`
- Username: `supplier4`, Password: `supplier4`
- Username: `supplier5`, Password: `supplier5`

## Data Structure

### Products
- 4 product categories (Grains, Vegetables, Fruits, Herbs)
- 8 products across these categories

### Orders
- 5 orders with different statuses (completed, delivered, processing, pending, cancelled)
- Each order has multiple order items
- Associated payment transactions

### Analytics
- Analytics events (views, cart actions, checkouts, payments)
- Pre-calculated sales reports (daily, weekly, monthly)
- Product and category performance metrics

## Custom Data

If you need to modify or add seed data, you can edit the JSON files in each app's fixtures directory:

- `apps/users/fixtures/initial_users.json`
- `apps/products/fixtures/initial_products.json`
- `apps/cart/fixtures/initial_carts.json`
- `apps/orders/fixtures/initial_orders.json`
- `apps/inventory/fixtures/initial_inventory.json`
- `apps/analytics/fixtures/initial_analytics.json`

After modifying, run the load_seed_data.sh script again to reload the data. 