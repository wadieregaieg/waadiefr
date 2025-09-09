# B2B Freshk - Image Upload & Fetch Guide

This document provides a comprehensive guide for frontend developers on how to handle product image uploads and fetching using the Base64-encoded API.

## 1. Overview

To simplify frontend development and streamline API requests, the backend has been updated to handle image data directly within JSON payloads. Instead of using `multipart/form-data`, all product images are now sent and received as **Base64-encoded strings** with a data URI prefix.

**Benefits of this approach:**
- No need to construct complex `FormData` objects.
- A single, unified request body for product data and images.
- Simplified state management on the client-side.

---

## 2. Key API Endpoints

There are two primary sets of endpoints for handling products, tailored for different roles:

| Role      | Endpoint                                 | Actions Allowed        | Used By        |
| :-------- | :--------------------------------------- | :--------------------- | :------------- |
| **Admin** | `/api/products/`                         | `GET`, `POST`, `PUT`, `PATCH` | Next.js Dashboard |
| **Supplier**| `/api/mobile/production/products/`     | `GET`, `POST`, `PUT`, `PATCH` | Flutter App (Supplier UI) |
| **Client**  | `/api/mobile/products/`                | `GET` (Read-only)      | Flutter App (Retailer UI) |

---

## 3. How to Upload an Image (Admin & Supplier)

When creating a new product or updating an existing one, the client application must encode the chosen image into a Base64 string and include it in the JSON request body.

### Step-by-Step Process:

1.  **User Selects an Image**: The user picks an image from their device.
2.  **Client-Side Encoding**: Before sending the API request, the client must:
    a. Read the image file's binary data.
    b. Encode this data into a Base64 string.
    c. Prepend the string with a "data URI" header: `data:image/[EXTENSION];base64,`.
3.  **API Request**: The full data URI string is sent in the `image` field of the JSON body.

### Example: JavaScript (Next.js)

Here's how you can create the Base64 string from a file input in JavaScript.

```javascript
const handleImageUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();

  reader.onloadend = () => {
    // The result includes the full data URI string
    // e.g., "data:image/jpeg;base64,/9j/4AAQSk..."
    const base64String = reader.result;
    
    // Now you can set this string in your component's state
    // and include it in your API request body.
    setProductData({ ...productData, image: base64String });
  };

  reader.readAsDataURL(file); // This does the magic
};
```

### Example Request Body:

This JSON is sent with a `POST` or `PUT`/`PATCH` request to the appropriate endpoint.

```json
{
  "name": "Fresh Tunisian Tomatoes",
  "price": "2.500",
  "stock_quantity": "150.000",
  "category": 1,
  "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAw..."
}
```

**Note:** If the `image` field is `null` or omitted on a `PUT` request, the product's image will be removed.

---

## 4. How to Fetch and Display an Image (Client Apps)

When you fetch product data from any of the endpoints, the API response will include the full Base64 data URI string in the `image` field if an image exists.

### Example API Response:

```json
{
  "id": 12,
  "name": "Fresh Tunisian Tomatoes",
  "price": "2.500",
  // ... other fields
  "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAw..."
}
```

### Rendering the Image:

#### In Next.js / React

You can pass the string directly to the `src` attribute of an `<img>` tag. The browser handles it automatically.

```jsx
<img 
  src={product.image || '/placeholder-image.png'} 
  alt={product.name} 
/>
```

#### In Flutter

Flutter requires you to decode the Base64 part of the string first before rendering it with an `Image.memory` widget.

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? base64String;

  const ProductImage({Key? key, this.base64String}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (base64String == null || !base64String!.contains(',')) {
      // Return a placeholder if the image string is invalid or null
      return Image.asset('assets/images/placeholder.png');
    }

    // Split the data URI header from the Base64 content
    final String base64Data = base64String!.split(',').last;
    
    try {
      final decodedBytes = base64Decode(base64Data);
      return Image.memory(
        decodedBytes,
        fit: BoxFit.cover,
      );
    } catch (e) {
      // Return a placeholder if decoding fails
      print('Error decoding Base64 image: $e');
      return Image.asset('assets/images/placeholder.png');
    }
  }
}

// How to use it:
// ProductImage(base64String: product['image'])
``` 