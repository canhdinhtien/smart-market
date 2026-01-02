# Smart Market API Endpoints

Base URL: `/api/v1`

## Authentication
All endpoints (except registration and login) require Bearer token authentication via cookies or Authorization header.

---

## Users (`/users`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/users` | Register a new user | ❌ |
| POST | `/users/login` | Login | ❌ |
| POST | `/users/logout` | Logout | ✅ |
| POST | `/users/refresh-token` | Refresh access token | ✅ |
| POST | `/users/send-verification-code` | Send verification email | ❌ |
| POST | `/users/verify-email` | Verify email with code | ❌ |
| POST | `/users/forgot-password` | Request password reset | ❌ |
| POST | `/users/reset-password` | Reset password with code | ❌ |
| POST | `/users/change-password` | Change password | ✅ |
| GET | `/users` | Get current user profile | ✅ |
| PUT | `/users` | Update user profile (multipart) | ✅ |
| DELETE | `/users` | Delete user account | ✅ |


---

## Groups (`/groups`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/groups` | Get all groups for current user | ✅ |
| POST | `/groups` | Create a new group | ✅ |
| GET | `/groups/{id}/members` | Get group members | ✅ |
| POST | `/groups/{id}/members` | Add member to group | ✅ |
| DELETE | `/groups/{id}/members/{userId}` | Remove member from group | ✅ |

---

## Food (`/food`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/food?group_id={id}` | Get all foods in group | ✅ |
| GET | `/food/{id}` | Get food by ID | ✅ |
| POST | `/food` | Create food item (multipart) | ✅ |
| PUT | `/food/{id}` | Update food item (multipart) | ✅ |
| DELETE | `/food/{id}` | Delete food item | ✅ |

---

## Categories (`/categories`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/categories` | Get all categories | ✅ |
| POST | `/categories` | Create category | ✅ Admin |
| PUT | `/categories` | Edit category by name | ✅ Admin |
| DELETE | `/categories` | Delete category by name | ✅ Admin |

---

## Units (`/units`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/units` | Get all units | ✅ |
| POST | `/units` | Create unit | ✅ Admin |
| PUT | `/units` | Edit unit by name | ✅ Admin |
| DELETE | `/units` | Delete unit by name | ✅ Admin |

---

## Fridge (`/fridge`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/fridge?group_id={id}` | Get all fridge items | ✅ |
| GET | `/fridge/{id}` | Get fridge item by ID | ✅ |
| POST | `/fridge` | Create fridge item | ✅ |
| PUT | `/fridge/{id}` | Update fridge item | ✅ |
| DELETE | `/fridge/{id}` | Delete fridge item | ✅ |

---

## Recipes (`/recipes`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/recipes?food_id={id}` | Get recipes by food ID | ✅ |
| POST | `/recipes` | Create recipe | ✅ |
| PUT | `/recipes/{id}` | Update recipe | ✅ |
| DELETE | `/recipes/{id}` | Delete recipe | ✅ |

---

## Meal Plans (`/meals`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/meals/{groupId}?startDate=&endDate=` | Get meal plans by date range | ✅ |
| POST | `/meals` | Create meal plan | ✅ |
| PUT | `/meals/{id}` | Update meal plan | ✅ |
| DELETE | `/meals/{id}` | Delete meal plan | ✅ |

---

## Shopping Lists (`/shopping`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/shopping?group_id={id}` | Get all shopping lists | ✅ |
| GET | `/shopping/{id}` | Get shopping list by ID | ✅ |
| POST | `/shopping` | Create shopping list | ✅ |
| PUT | `/shopping/{id}` | Update shopping list | ✅ |
| DELETE | `/shopping/{id}` | Delete shopping list | ✅ |
| GET | `/shopping/{id}/tasks` | Get tasks in list | ✅ |
| POST | `/shopping/{id}/tasks` | Create tasks | ✅ |
| PUT | `/shopping/tasks/{taskId}` | Update task | ✅ |
| DELETE | `/shopping/tasks/{taskId}` | Delete task | ✅ |

---

## Notifications (`/notifications`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/notifications/register-fcm` | Register FCM token | ✅ |
| POST | `/notifications/send` | Send notification | ✅ |

---

## Logs (`/logs`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/logs` | Get logs | ✅ |

---

## Notes
- **Auth Legend**: ✅ = Required, ❌ = Not required, Admin = Admin only
- **Multipart**: Endpoints marked with (multipart) accept `multipart/form-data` for file uploads
- **Group Membership**: All group-related resources (food, fridge, recipes, meals, shopping) enforce group membership checks
