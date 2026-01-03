# API Endpoints

## Base URL
`/api/v1`

## Users

### Register a new user
- **Name**: Register User
- **Method**: `POST`
- **Authorization**: None
- **Path**: `/users`
- **Content Type**: `application/json`
- **Body Schema**: `{ "email": "string", "password": "string (min 6 chars)", "name": "string", "gender": "string (male|female|other)" }`

### Login
- **Name**: Login
- **Method**: `POST`
- **Authorization**: None
- **Path**: `/users/login`
- **Content Type**: `application/json`
- **Body Schema**: `{ "identifier": "string (email)", "password": "string" }`

### Logout
- **Name**: Logout
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/users/logout`
- **Content Type**: None

### Refresh Token
- **Name**: Refresh Access Token
- **Method**: `POST`
- **Authorization**: None
- **Path**: `/users/refresh-token`
- **Content Type**: `application/json`
- **Body Schema**: `{ "refreshToken": "string" }`

### Send Verification Code
- **Name**: Send Verification Code
- **Method**: `POST`
- **Authorization**: None
- **Path**: `/users/send-verification-code`
- **Content Type**: `application/json`
- **Body Schema**: `{ "email": "string" }`

### Verify Email
- **Name**: Verify Email
- **Method**: `POST`
- **Authorization**: None
- **Path**: `/users/verify-email`
- **Content Type**: `application/json`
- **Body Schema**: `{ "code": "string", "token": "string" }`

### Search Users
- **Name**: Search Users
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/users/search`
- **Query Params**: `q (optional): string`, `page (optional): integer (Default: 1)`, `limit (optional): integer (Default: 20)`

### Get Current Profile
- **Name**: Get Profile
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/users`

### Update Profile
- **Name**: Update Profile
- **Method**: `PUT`
- **Authorization**: Bearer Token
- **Path**: `/users`
- **Content Type**: `multipart/form-data`
- **Body Schema**: `Form-Data: { "name": "string", "gender": "string", "email": "string", "profile_pic": "file" }`

### Delete Self
- **Name**: Delete Account
- **Method**: `DELETE`
- **Authorization**: Bearer Token
- **Path**: `/users`

### Delete User (Admin)
- **Name**: Delete User (Admin)
- **Method**: `DELETE`
- **Authorization**: Bearer Token (Admin)
- **Path**: `/users/:id`

### Request Password Reset
- **Name**: Forgot Password
- **Method**: `POST`
- **Authorization**: None
- **Path**: `/users/forgot-password`
- **Content Type**: `application/json`
- **Body Schema**: `{ "email": "string" }`

### Reset Password
- **Name**: Reset Password
- **Method**: `POST`
- **Authorization**: None
- **Path**: `/users/reset-password`
- **Content Type**: `application/json`
- **Body Schema**: `{ "code": "string", "token": "string", "newPassword": "string (min 6 chars)" }`

### Change Password
- **Name**: Change Password
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/users/change-password`
- **Content Type**: `application/json`
- **Body Schema**: `{ "oldPassword": "string", "newPassword": "string (min 6 chars)" }`

---

## Groups

### Get All Groups
- **Name**: Get User Groups
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/groups`
- **Query Params**: `page (optional): integer (Default: 1)`, `limit (optional): integer (Default: 20)`, `name (optional): string`

### Create Group
- **Name**: Create Group
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/groups`
- **Content Type**: `application/json`
- **Body Schema**: `{ "name": "string" }`

### Get Group Members
- **Name**: Get Group Members
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/groups/:id/members`
- **Query Params**: `page (optional): integer`, `limit (optional): integer`, `name (optional): string`

### Add Member
- **Name**: Add Member
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/groups/:id/members`
- **Content Type**: `application/json`
- **Body Schema**: `{ "userId": "integer" }`

### Remove Member
- **Name**: Remove Member
- **Method**: `DELETE`
- **Authorization**: Bearer Token
- **Path**: `/groups/:id/members/:userId`

---

## Food

### Get Foods
- **Name**: Get Foods in Group
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/food`
- **Query Params**: `group_id (required): string`, `page (optional): integer`, `limit (optional): integer`, `name (optional): string`, `category_id (optional): integer`

### Get Food by ID
- **Name**: Get Food Details
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/food/:id`

### Create Food
- **Name**: Create Food
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/food`
- **Content Type**: `multipart/form-data`
- **Body Schema**: `Form-Data: { "name": "string", "group_id": "string", "category_id": "string", "unit_id": "string", "quantity": "number", "image": "file" }`

### Update Food
- **Name**: Update Food
- **Method**: `PUT`
- **Authorization**: Bearer Token
- **Path**: `/food/:id`
- **Content Type**: `multipart/form-data`
- **Body Schema**: `Form-Data: { "name": "string", "category_id": "string", "unit_id": "string", "quantity": "number", "image": "file" }`

### Delete Food
- **Name**: Delete Food
- **Method**: `DELETE`
- **Authorization**: Bearer Token
- **Path**: `/food/:id`

---

## Fridge

### Get Fridge Items
- **Name**: Get Fridge Inventory
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/fridge`
- **Query Params**: `group_id (required): string`, `page (optional): integer`, `limit (optional): integer`, `name (optional): string`

### Get Item by ID
- **Name**: Get Fridge Item
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/fridge/:id`

### Add Item
- **Name**: Add to Fridge
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/fridge`
- **Content Type**: `application/json`
- **Body Schema**: `{ "food_id": "string", "group_id": "string", "quantity": "number", "expiryDate": "string (YYYY-MM-DD)" }`

### Update Item
- **Name**: Update Fridge Item
- **Method**: `PUT`
- **Authorization**: Bearer Token
- **Path**: `/fridge/:id`
- **Content Type**: `application/json`
- **Body Schema**: `{ "quantity": "number", "expiryDate": "string (YYYY-MM-DD)" }`

### Remove Item
- **Name**: Remove from Fridge
- **Method**: `DELETE`
- **Authorization**: Bearer Token
- **Path**: `/fridge/:id`

---

## Recipes

### Get Recipes
- **Name**: Get Recipes
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/recipes`
- **Query Params**: `group_id (required if no foodId): string`, `foodId (required if no group_id): string`, `name (optional): string`, `page (optional): integer`, `limit (optional): integer`

### Create Recipe
- **Name**: Create Recipe
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/recipes`
- **Content Type**: `multipart/form-data`
- **Body Schema**: `Form-Data: { "name": "string", "group_id": "string", "instructions": "string", "description": "string", "image": "file", "ingredients": "array (JSON string: [{food_id, quantity, unit_id}])" }`

### Get Recommendations
- **Name**: Get Recipe Recommendations
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/recipes/recommendations`
- **Query Params**: `group_id (required): string`, `page (optional): integer`, `limit (optional): integer`

### Update Recipe
- **Name**: Update Recipe
- **Method**: `PUT`
- **Authorization**: Bearer Token
- **Path**: `/recipes/:id`
- **Content Type**: `multipart/form-data`
- **Body Schema**: `Form-Data: { "name": "string", "instructions": "string", "description": "string", "image": "file", "ingredients": "array (JSON string: [{food_id, quantity, unit_id}])" }`

### Delete Recipe
- **Name**: Delete Recipe
- **Method**: `DELETE`
- **Authorization**: Bearer Token
- **Path**: `/recipes/:id`

---

## Shopping Lists

### Get All Lists
- **Name**: Get Shopping Lists
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/shopping`
- **Query Params**: `group_id (required): string`, `page (optional): integer`, `limit (optional): integer`, `name (optional): string`

### Get List by ID
- **Name**: Get Shopping List
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/shopping/:id`

### Create List
- **Name**: Create Shopping List
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/shopping`
- **Content Type**: `application/json`
- **Body Schema**: `{ "name": "string" }`

### Update List
- **Name**: Update Shopping List
- **Method**: `PUT`
- **Authorization**: Bearer Token
- **Path**: `/shopping/:id`
- **Content Type**: `application/json`
- **Body Schema**: `{ "name": "string" }`

### Delete List
- **Name**: Delete Shopping List
- **Method**: `DELETE`
- **Authorization**: Bearer Token
- **Path**: `/shopping/:id`

### Create Tasks
- **Name**: Add Tasks to List
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/shopping/:id/tasks`
- **Content Type**: `application/json`
- **Body Schema**: `Array of Objects: [{ "food_id": "integer", "quantity": "number", "unit_id": "integer", "note": "string", "assign_to_user_id": "integer" }]`

### Get Tasks
- **Name**: Get Tasks
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/shopping/:id/tasks`
- **Query Params**: `page (optional): integer`, `limit (optional): integer`, `name (optional): string`, `is_purchased (optional): boolean`

### Update Task
- **Name**: Update Task
- **Method**: `PUT`
- **Authorization**: Bearer Token
- **Path**: `/shopping/tasks/:taskId`
- **Content Type**: `application/json`
- **Body Schema**: `{ "name": "string", "quantity": "number", "is_purchased": "boolean" }`

### Delete Task
- **Name**: Delete Task
- **Method**: `DELETE`
- **Authorization**: Bearer Token
- **Path**: `/shopping/tasks/:taskId`

---

## Meal Plans

### Get Meal Plans
- **Name**: Get Meal Plan
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/meals/:groupId`
- **Query Params**: `startDate (optional): string (YYYY-MM-DD)`, `endDate (optional): string (YYYY-MM-DD)`, `page (optional): integer`, `limit (optional): integer`

### Create Plan
- **Name**: Create Meal Plan
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/meals`
- **Content Type**: `application/json`
- **Body Schema**: `{ "date": "string (YYYY-MM-DD)", "meal_type": "string (sang|trua|toi)", "group_id": "integer", "recipe_id": "integer (optional)", "food_id": "integer (optional)" }`

### Update Plan
- **Name**: Update Meal Plan
- **Method**: `PUT`
- **Authorization**: Bearer Token
- **Path**: `/meals/:id`
- **Content Type**: `application/json`
- **Body Schema**: `{ "date": "string (YYYY-MM-DD)", "meal_type": "string (sang|trua|toi)", "recipe_id": "integer (optional)", "food_id": "integer (optional)" }`

### Delete Plan
- **Name**: Delete Meal Plan
- **Method**: `DELETE`
- **Authorization**: Bearer Token
- **Path**: `/meals/:id`

---

## Categories

### Get Categories
- **Name**: Get All Categories
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/categories`
- **Query Params**: `page (optional): integer`, `limit (optional): integer`, `name (optional): string`

### Create Category
- **Name**: Create Category (Admin)
- **Method**: `POST`
- **Authorization**: Bearer Token (Admin)
- **Path**: `/categories`
- **Content Type**: `application/json`
- **Body Schema**: `{ "name": "string" }`

### Update Category
- **Name**: Update Category (Admin)
- **Method**: `PUT`
- **Authorization**: Bearer Token (Admin)
- **Path**: `/categories`
- **Content Type**: `application/json`
- **Body Schema**: `{ "oldName": "string", "newName": "string" }`

### Delete Category
- **Name**: Delete Category (Admin)
- **Method**: `DELETE`
- **Authorization**: Bearer Token (Admin)
- **Path**: `/categories`
- **Content Type**: `application/json`
- **Body Schema**: `{ "name": "string" }`

---

## Units

### Get Units
- **Name**: Get All Units
- **Method**: `GET`
- **Authorization**: Bearer Token
- **Path**: `/units`
- **Query Params**: `page (optional): integer`, `limit (optional): integer`, `name (optional): string`

### Create Unit
- **Name**: Create Unit (Admin)
- **Method**: `POST`
- **Authorization**: Bearer Token (Admin)
- **Path**: `/units`
- **Content Type**: `application/json`
- **Body Schema**: `{ "unitName": "string" }`

### Update Unit
- **Name**: Update Unit (Admin)
- **Method**: `PUT`
- **Authorization**: Bearer Token (Admin)
- **Path**: `/units`
- **Content Type**: `application/json`
- **Body Schema**: `{ "oldName": "string", "newName": "string" }`

### Delete Unit
- **Name**: Delete Unit (Admin)
- **Method**: `DELETE`
- **Authorization**: Bearer Token (Admin)
- **Path**: `/units`
- **Content Type**: `application/json`
- **Body Schema**: `{ "unitName": "string" }`

---

## Notifications

### Register Device
- **Name**: Register FCM Token
- **Method**: `POST`
- **Authorization**: Bearer Token
- **Path**: `/notifications/register-fcm`
- **Content Type**: `application/json`
- **Body Schema**: `{ "fcm_token": "string", "platform": "string (android|ios|web)", "device_id": "string (optional)" }`

### Send Notification
- **Name**: Send Notification
- **Method**: `POST`
- **Authorization**: Bearer Token (Admin/Dev)
- **Path**: `/notifications/send`
- **Content Type**: `application/json`
- **Body Schema**: `{ "userId": "integer", "title": "string", "body": "string", "data": "object" }`

---

## Logs

### Get Logs
- **Name**: Get System Logs
- **Method**: `GET`
- **Authorization**: Bearer Token (Admin)
- **Path**: `/logs`
- **Query Params**: `page (optional): integer`, `limit (optional): integer`
