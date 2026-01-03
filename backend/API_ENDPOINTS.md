# Smart Market API Documentation

Base URL: `/api/v1`

## Authentication
Most endpoints require a Bearer Token.
- **Header**: `Authorization: Bearer <your_access_token>`
- **Legend**:
  - 🔓 Public
  - 🔒 Authenticated User
  - 🛡️ Admin Only

---

## 👤 Users (`/users`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/users` | 🔓 | **Register a new user**<br>**Body**: `{ email, password, name, gender }` |
| `POST` | `/users/login` | 🔓 | **Login**<br>**Body**: `{ identifier, password }`<br>**Returns**: `{ user, accessToken, refreshToken }` |
| `POST` | `/users/logout` | 🔒 | **Logout** |
| `POST` | `/users/refresh-token` | 🔓 | **Refresh Access Token**<br>**Body**: `{ refreshToken }`<br>**Returns**: `{ accessToken }` |
| `GET` | `/users/search` | 🔒 | **Search Users**<br>**Query Params**:<br>• `q` (string, optional): Search by name or email<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page |
| `GET` | `/users` | 🔒 | **Get Current Profile** |
| `PUT` | `/users` | 🔒 | **Update Profile** (Multipart)<br>**Form-Data**: `name`, `gender`, `profile_pic` (file) |
| `DELETE` | `/users` | 🔒 | **Delete Self** |
| `DELETE` | `/users/:id` | 🛡️ | **Delete User (Admin)** |
| `POST` | `/users/send-verification-code` | 🔓 | **Send Email Verification**<br>**Body**: `{ email }` |
| `POST` | `/users/verify-email` | 🔓 | **Verify Email**<br>**Body**: `{ code, token }` |
| `POST` | `/users/forgot-password` | 🔓 | **Request Password Reset**<br>**Body**: `{ email }` |
| `POST` | `/users/reset-password` | 🔓 | **Reset Password**<br>**Body**: `{ code, token, newPassword }` |
| `POST` | `/users/change-password` | 🔒 | **Change Password**<br>**Body**: `{ oldPassword, newPassword }` |

---

## 👥 Groups (`/groups`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/groups` | 🔒 | **Get All Groups**<br>**Query Params**:<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page<br>• `name` (string, optional): Filter by group name |
| `POST` | `/groups` | 🔒 | **Create Group**<br>**Body**: `{ name }` |
| `GET` | `/groups/:id/members` | 🔒 | **Get Group Members**<br>**Query Params**:<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page<br>• `name` (string, optional): Filter by member name or email |
| `POST` | `/groups/:id/members` | 🔒 | **Add Member**<br>**Body**: `{ userId }` |
| `DELETE` | `/groups/:id/members/:userId` | 🔒 | **Remove Member** |

---

## 🍎 Food (`/food`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/food` | 🔒 | **Get Foods in Group**<br>**Query Params**:<br>• `group_id` (string, **required**): Group ID to get foods from<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page<br>• `name` (string, optional): Filter by food name<br>• `category_id` (integer, optional): Filter by category ID |
| `GET` | `/food/:id` | 🔒 | **Get Food by ID** |
| `POST` | `/food` | 🔒 | **Create Food** (Multipart)<br>**Form-Data**: `name`, `group_id`, `category`, `unit`, `quantity`, `image` (file) |
| `PUT` | `/food/:id` | 🔒 | **Update Food** (Multipart)<br>**Form-Data**: `name`, `category`, `unit`, `quantity`, `image` (file) |
| `DELETE` | `/food/:id` | 🔒 | **Delete Food** |

---

## ❄️ Fridge (`/fridge`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/fridge` | 🔒 | **Get Fridge Items**<br>**Query Params**:<br>• `group_id` (string, **required**): Group ID to get fridge items from<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page<br>• `name` (string, optional): Filter by food name |
| `GET` | `/fridge/:id` | 🔒 | **Get Item by ID** |
| `POST` | `/fridge` | 🔒 | **Add Item**<br>**Body**: `{ food_id, group_id, quantity, expiryDate (YYYY-MM-DD) }` |
| `PUT` | `/fridge/:id` | 🔒 | **Update Item**<br>**Body**: `{ quantity, expiryDate }` |
| `DELETE` | `/fridge/:id` | 🔒 | **Remove Item** |

---

## 🏷️ Categories (`/categories`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/categories` | 🔒 | **Get All Categories**<br>**Query Params**:<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page<br>• `name` (string, optional): Filter by category name |
| `POST` | `/categories` | 🛡️ | **Create Category**<br>**Body**: `{ name }` |
| `PUT` | `/categories` | 🛡️ | **Update Category**<br>**Body**: `{ oldName, newName }` |
| `DELETE` | `/categories` | 🛡️ | **Delete Category**<br>**Body**: `{ name }` |

---

## 📏 Units (`/units`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/units` | 🔒 | **Get All Units**<br>**Query Params**:<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page<br>• `name` (string, optional): Filter by unit name |
| `POST` | `/units` | 🛡️ | **Create Unit**<br>**Body**: `{ unitName }` |
| `PUT` | `/units` | 🛡️ | **Update Unit**<br>**Body**: `{ oldName, newName }` |
| `DELETE` | `/units` | 🛡️ | **Delete Unit**<br>**Body**: `{ unitName }` |

---

## 🍳 Recipes (`/recipes`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/recipes` | 🔒 | **Get Recipes**<br>**Query Params** (either `foodId` OR `group_id` required):<br>• `foodId` (string, optional): Get recipes for specific food<br>• `group_id` (string, optional): Get recipes for group<br>• `name` (string, optional): Filter by recipe name<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page |
| `POST` | `/recipes` | 🔒 | **Create Recipe**<br>**Body**: `{ name, description, instructions, group_id, ingredients: [{ food_id, quantity, unit_id }] }` |
| `GET` | `/recipes/recommendations` | 🔒 | **Get Recommendations**<br>**Query Params**:<br>• `group_id` (string, **required**): Group ID<br>• `page` (integer, optional): Page number<br>• `limit` (integer, optional): Items per page<br>**Returns**: Recipes matched with fridge items, sorted by match % then matched count |
| `PUT` | `/recipes/:id` | 🔒 | **Update Recipe**<br>**Body**: `{ name, description, instructions, ingredients }` |
| `DELETE` | `/recipes/:id` | 🔒 | **Delete Recipe** |

---

## 📅 Meal Plans (`/meals`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/meals/:groupId` | 🔒 | **Get Meal Plans**<br>**Query Params**:<br>• `startDate` (string, optional, format: YYYY-MM-DD): Filter from date<br>• `endDate` (string, optional, format: YYYY-MM-DD): Filter to date<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page |
| `POST` | `/meals` | 🔒 | **Create Plan**<br>**Body**: `{ date, meals: [{...}] }` |
| `PUT` | `/meals/:id` | 🔒 | **Update Plan**<br>**Body**: `{ date, meals }` |
| `DELETE` | `/meals/:id` | 🔒 | **Delete Plan** |

---

## 🛒 Shopping Lists (`/shopping`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/shopping` | 🔒 | **Get All Lists**<br>**Query Params**:<br>• `group_id` (string, **required**): Group ID to get shopping lists from<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page<br>• `name` (string, optional): Filter by list name<br>**Returns**: Lists with full task details |
| `GET` | `/shopping/:id` | 🔒 | **Get List by ID**<br>**Returns**: List with full task details |
| `POST` | `/shopping` | 🔒 | **Create List**<br>**Body**: `{ name }` |
| `PUT` | `/shopping/:id` | 🔒 | **Update List**<br>**Body**: `{ name }` |
| `DELETE` | `/shopping/:id` | 🔒 | **Delete List** |
| `GET` | `/shopping/:id/tasks` | 🔒 | **Get Tasks**<br>**Query Params**:<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page<br>• `name` (string, optional): Filter by food name<br>• `is_purchased` (boolean, optional): Filter by purchase status |
| `POST` | `/shopping/:id/tasks` | 🔒 | **Add Tasks**<br>**Body**: `{ tasks: [{ food_id, quantity, unit_id, note, assign_to_user_id }] }` |
| `PUT` | `/shopping/tasks/:taskId` | 🔒 | **Update Task**<br>**Body**: `{ quantity, is_purchased, note, assign_to_user_id }` |
| `DELETE` | `/shopping/tasks/:taskId` | 🔒 | **Delete Task** |

---

## 🔔 Notifications (`/notifications`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/notifications/register-fcm` | 🔒 | **Register Device**<br>**Body**: `{ user_id, fcm_token, platform, device_id }`<br>**Returns**: `{ message: "Device registered" }` |
| `POST` | `/notifications/send` | 🔒 | **Send Notification** (Dev)<br>**Body**: `{ user_id, title, body, data }`<br>**Returns**: `{ message: "Notification sent" }` |

---

## 📜 Logs (`/logs`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/logs` | 🛡️ | **Get System Logs**<br>**Query Params**:<br>• `page` (integer, optional, default=1): Page number<br>• `limit` (integer, optional, default=20): Items per page |

---

## 🚦 Response Codes

| Code | Status | Description | Possible Messages |
| :--- | :--- | :--- | :--- |
| `200` | OK | Request succeeded. | `Login successful!`, `Logout successful!`, `User registered successfully!`, `Access token refreshed successfully`, `User updated successfully`, `Password changed successfully`, `Password reset successfully`, `Email verified successfully`, `Verification code sent successfully.`, `[Entity] deleted successfully`, `Member added successfully`, `Member removed successfully`, `Recipe updated successfully`, `Meal plan updated successfully`, `Fridge item deleted successfully`, `Food deleted successfully` |
| `201` | Created | Resource created successfully. | `User registered successfully!`, `Recipe created successfully`, `Meal plan created successfully`, `[Entity] created successfully` |
| `400` | Bad Request | Invalid input or missing fields. | `[Field] is required`, `Invalid meal type`, `Password must be at least 6 characters`, `Invalid verification code`, `Verification code expired or not found`, `Invalid token`, `Invalid reset code`, `Reset code expired or not found`, `Group ID is required`, `Food ID is required`, `Name and group_id are required`, `Invalid meal type. Must be sang, trua, or toi` |
| `401` | Unauthorized | Auth missing or invalid. | `Unauthorized: User ID missing`, `Refresh token not found`, `Invalid credentials!`, `User is not verified!`, `Invalid token`, `Invalid password`, `Failed to refresh token` |
| `403` | Forbidden | Good token, bad permissions. | `Only group admin can [action]`, `Access denied: You must be a member of the group to [action]`, `Access denied: You must be a member or admin to view this group` |
| `404` | Not Found | Resource not found. | `User not found`, `Group not found`, `Food not found`, `Recipe not found`, `Shopping list not found`, `Task not found`, `Meal plan not found`, `Fridge item not found`, `Category not found`, `Unit not found`, `User not in group`, `Reset code expired or not found` |
| `409` | Conflict | Resource conflict. | `User already exists`, `Email already exists`, `User already in group`, `Category already exists`, `Unit already exists`, `Food with this name already exists in the group`, `This email is already associated with a verified account.` |
| `500` | Internal Server Error | Unexpected error. | `Failed to [action]`, `Unexpected server error`, `Error sending notification` |
