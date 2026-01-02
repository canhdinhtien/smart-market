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
| `GET` | `/users` | 🔒 | **Get Current Profile** |
| `PUT` | `/users` | 🔒 | **Update Profile** (Multipart)<br>**Form-Data**: `name`, `gender`, `profile_pic` (file) |
| `DELETE` | `/users` | 🔒 | **Delete Account** |
| `POST` | `/users/send-verification-code` | 🔓 | **Send Email Verification**<br>**Body**: `{ email }` |
| `POST` | `/users/verify-email` | 🔓 | **Verify Email**<br>**Body**: `{ code, token }` |
| `POST` | `/users/forgot-password` | 🔓 | **Request Password Reset**<br>**Body**: `{ email }` |
| `POST` | `/users/reset-password` | 🔓 | **Reset Password**<br>**Body**: `{ code, token, newPassword }` |
| `POST` | `/users/change-password` | 🔒 | **Change Password**<br>**Body**: `{ oldPassword, newPassword }` |

---

## 👥 Groups (`/groups`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/groups` | 🔒 | **Get All Groups** |
| `POST` | `/groups` | 🔒 | **Create Group**<br>**Body**: `{ name }` |
| `GET` | `/groups/:id/members` | 🔒 | **Get Group Members** |
| `POST` | `/groups/:id/members` | 🔒 | **Add Member**<br>**Body**: `{ userId }` |
| `DELETE` | `/groups/:id/members/:userId` | 🔒 | **Remove Member** |

---

## 🍎 Food (`/food`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/food` | 🔒 | **Get Foods in Group**<br>**Query**: `?group_id=<id>` |
| `GET` | `/food/:id` | 🔒 | **Get Food by ID** |
| `POST` | `/food` | 🔒 | **Create Food** (Multipart)<br>**Form-Data**: `name`, `group_id`, `category`, `unit`, `quantity`, `image` (file) |
| `PUT` | `/food/:id` | 🔒 | **Update Food** (Multipart)<br>**Form-Data**: `name`, `category`, `unit`, `quantity`, `image` (file) |
| `DELETE` | `/food/:id` | 🔒 | **Delete Food** |

---

## ❄️ Fridge (`/fridge`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/fridge` | 🔒 | **Get Fridge Items**<br>**Query**: `?group_id=<id>` |
| `GET` | `/fridge/:id` | 🔒 | **Get Item by ID** |
| `POST` | `/fridge` | 🔒 | **Add Item**<br>**Body**: `{ food_id, group_id, quantity, expiryDate (YYYY-MM-DD) }` |
| `PUT` | `/fridge/:id` | 🔒 | **Update Item**<br>**Body**: `{ quantity, expiryDate }` |
| `DELETE` | `/fridge/:id` | 🔒 | **Remove Item** |

---

## 🏷️ Categories (`/categories`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/categories` | 🔒 | **Get All Categories** |
| `POST` | `/categories` | 🛡️ | **Create Category**<br>**Body**: `{ name }` |
| `PUT` | `/categories` | 🛡️ | **Update Category**<br>**Body**: `{ oldName, newName }` |
| `DELETE` | `/categories` | 🛡️ | **Delete Category**<br>**Body**: `{ name }` |

---

## 📏 Units (`/units`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/units` | 🔒 | **Get All Units** |
| `POST` | `/units` | 🛡️ | **Create Unit**<br>**Body**: `{ unitName }` |
| `PUT` | `/units` | 🛡️ | **Update Unit**<br>**Body**: `{ oldName, newName }` |
| `DELETE` | `/units` | 🛡️ | **Delete Unit**<br>**Body**: `{ unitName }` |

---

## 🍳 Recipes (`/recipes`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/recipes` | 🔒 | **Get Recipes**<br>**Query**: `?foodId=<id>` |
| `POST` | `/recipes` | 🔒 | **Create Recipe**<br>**Body**: `{ foodId, instructions, ingredients: [{...}] }` |
| `PUT` | `/recipes/:id` | 🔒 | **Update Recipe**<br>**Body**: `{ name, instructions, ingredients }` |
| `DELETE` | `/recipes/:id` | 🔒 | **Delete Recipe** |

---

## 📅 Meal Plans (`/meals`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/meals/:groupId` | 🔒 | **Get Meal Plans**<br>**Query**: `?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD` |
| `POST` | `/meals` | 🔒 | **Create Plan**<br>**Body**: `{ date, meals: [{...}] }` |
| `PUT` | `/meals/:id` | 🔒 | **Update Plan**<br>**Body**: `{ date, meals }` |
| `DELETE` | `/meals/:id` | 🔒 | **Delete Plan** |

---

## 🛒 Shopping Lists (`/shopping`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/shopping` | 🔒 | **Get All Lists**<br>**Query**: `?group_id=<id>`<br>**Returns**: Lists with full task details |
| `GET` | `/shopping/:id` | 🔒 | **Get List by ID**<br>**Returns**: List with full task details |
| `POST` | `/shopping` | 🔒 | **Create List**<br>**Body**: `{ name }` |
| `PUT` | `/shopping/:id` | 🔒 | **Update List**<br>**Body**: `{ name }` |
| `DELETE` | `/shopping/:id` | 🔒 | **Delete List** |
| `GET` | `/shopping/:id/tasks` | 🔒 | **Get Tasks** |
| `POST` | `/shopping/:id/tasks` | 🔒 | **Add Tasks**<br>**Body**: `{ tasks: [{ name, quantity }] }` |
| `PUT` | `/shopping/tasks/:taskId` | 🔒 | **Update Task**<br>**Body**: `{ name, quantity, completed }` |
| `DELETE` | `/shopping/tasks/:taskId` | 🔒 | **Delete Task** |

---

## 🔔 Notifications (`/notifications`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/notifications/register-fcm` | 🔒 | **Register Device**<br>**Body**: `{ fcm_token, platform, device_id }` |
| `POST` | `/notifications/send` | 🔒 | **Send Notification** (Dev)<br>**Body**: `{ userId, title, body, data }` |

---

## 📜 Logs (`/logs`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/logs` | 🛡️ | **Get System Logs** |

---

## 🚦 Response Codes

| Code | Status | Description |
| :--- | :--- | :--- |
| `200` | OK | Request succeeded. |
| `201` | Created | Resource created successfully. |
| `400` | Bad Request | Invalid input or missing required fields. |
| `401` | Unauthorized | Authorization header missing or invalid token. |
| `403` | Forbidden | Valid token but insufficient permissions (e.g., Admin only). |
| `404` | Not Found | Resource (user, group, item) not found. |
| `409` | Conflict | Resource already exists (e.g., duplicate email/category). |
| `500` | Internal Server Error | Unexpected server error. |
