# CRC Cards

## Models

| **Category (Danh mục)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho một danh mục thực phẩm (ví dụ: "Rau củ", "Thịt").<br>- Lưu trữ tên danh mục.<br>- Hỗ trợ xóa mềm (soft delete). | - **Food**: Một danh mục có nhiều thực phẩm. |

| **Consumption (Tiêu thụ)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Theo dõi việc tiêu thụ các món trong tủ lạnh.<br>- Lưu số lượng tiêu thụ, ngày tháng và ghi chú của người dùng.<br>- Liên kết việc tiêu thụ với một người dùng và nhóm cụ thể. | - **FridgeItem**: Tham chiếu đến món đã tiêu thụ.<br>- **User**: Tham chiếu đến người dùng đã tiêu thụ.<br>- **Group**: Tham chiếu đến nhóm xảy ra việc tiêu thụ. |

| **Food (Thực phẩm)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho một loại thực phẩm.<br>- Lưu tên thực phẩm, URL hình ảnh.<br>- Liên kết xác thực với đơn vị và danh mục.<br>- Giới hạn trong một nhóm cụ thể. | - **Category**: Thuộc về một danh mục.<br>- **Unit**: Thuộc về một đơn vị.<br>- **Group**: Thuộc về một nhóm.<br>- **FridgeItem**: Được tham chiếu bởi các món trong tủ lạnh.<br>- **RecipeIngredient**: Được tham chiếu bởi nguyên liệu công thức.<br>- **ShoppingListTask**: Được tham chiếu bởi nhiệm vụ mua sắm.<br>- **MealPlan**: Được tham chiếu bởi kế hoạch bữa ăn. |

| **FridgeItem (Món trong tủ lạnh)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho một món thực phẩm cụ thể trong tủ lạnh.<br>- Theo dõi số lượng, ngày hết hạn và vị trí.<br>- Theo dõi số ngày "sử dụng trong vòng".<br>- Giới hạn trong một nhóm. | - **Food**: Tham chiếu đến định nghĩa thực phẩm.<br>- **Group**: Thuộc về một nhóm.<br>- **Consumption**: Được tham chiếu bởi các bản ghi tiêu thụ. |

| **Group (Nhóm)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho nhóm người dùng (ví dụ: "Gia đình", "Bạn cùng phòng").<br>- Lưu tên nhóm.<br>- Quản lý quyền quản trị.<br>- Đóng vai trò phạm vi chính cho hầu hết các thực thể dữ liệu. | - **User**: Có một quản trị viên và nhiều thành viên.<br>- **GroupMember**: Bảng liên kết cho các thành viên.<br>- **Food**: Sở hữu thực phẩm.<br>- **FridgeItem**: Sở hữu các món trong tủ lạnh.<br>- **Recipe**: Sở hữu các công thức.<br>- **ShoppingList**: Sở hữu các danh sách mua sắm.<br>- **MealPlan**: Sở hữu các kế hoạch bữa ăn. |

| **GroupMember (Thành viên nhóm)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Mô hình liên kết giữa Người dùng và Nhóm.<br>- Theo dõi thời điểm người dùng tham gia nhóm. | - **User**: Tham chiếu đến thành viên.<br>- **Group**: Tham chiếu đến nhóm. |

| **Log (Nhật ký)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Ghi lại các hoạt động hệ thống và hành động của người dùng.<br>- Lưu loại hành động, chi tiết và thực thể mục tiêu.<br>- Cung cấp dấu vết kiểm toán. | - **User**: Tham chiếu đến người dùng thực hiện hành động. |

| **MealPlan (Kế hoạch bữa ăn)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho bữa ăn đã lên kế hoạch cho ngày giờ cụ thể (sáng, trưa, tối).<br>- Các trường chính: ngày, loại bữa ăn, ghi chú.<br>- Có thể tham chiếu đến Công thức HOẶC món Thực phẩm. | - **Group**: Thuộc về một nhóm.<br>- **Recipe**: Tham chiếu tùy chọn đến công thức.<br>- **Food**: Tham chiếu tùy chọn đến món thực phẩm. |

| **Recipe (Công thức)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho công thức nấu ăn.<br>- Lưu tên, mô tả và hướng dẫn.<br>- Tập hợp các nguyên liệu. | - **Group**: Thuộc về một nhóm.<br>- **RecipeIngredient**: Có nhiều nguyên liệu.<br>- **MealPlan**: Được tham chiếu bởi kế hoạch bữa ăn. |

| **RecipeIngredient (Nguyên liệu công thức)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Liên kết món Thực phẩm với Công thức cùng số lượng cụ thể.<br>- Xác định số lượng và đơn vị cho nguyên liệu. | - **Recipe**: Thuộc về một công thức.<br>- **Food**: Tham chiếu đến món thực phẩm.<br>- **Unit**: Tham chiếu đến đơn vị đo lường. |

| **ShoppingList (Danh sách mua sắm)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho danh sách các món cần mua.<br>- Lưu tên danh sách, ngày mục tiêu và ghi chú. | - **Group**: Thuộc về một nhóm.<br>- **ShoppingListTask**: Chứa nhiều nhiệm vụ (món hàng). |

| **ShoppingListTask (Nhiệm vụ mua sắm)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho món cụ thể cần mua trong danh sách mua sắm.<br>- Theo dõi số lượng và trạng thái đã mua.<br>- Có thể được giao cho một người dùng cụ thể. | - **ShoppingList**: Thuộc về một danh sách.<br>- **Food**: Tham chiếu đến món thực phẩm cần mua.<br>- **User**: Người được giao (tùy chọn). |

| **Unit (Đơn vị)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho đơn vị đo lường (ví dụ: "kg", "g", "lít").<br>- Lưu tên đơn vị.<br>- Hỗ trợ xóa mềm. | - **Food**: Một đơn vị được sử dụng bởi nhiều thực phẩm.<br>- **RecipeIngredient**: Một đơn vị được sử dụng trong các nguyên liệu công thức. |

| **User (Người dùng)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đại diện cho người dùng đã đăng ký.<br>- Lưu dữ liệu xác thực (email, mã băm mật khẩu).<br>- Lưu dữ liệu hồ sơ (tên, giới tính, hình ảnh).<br>- Quản lý trạng thái xác minh và quản trị. | - **UserDevice**: Có nhiều thiết bị (cho thông báo).<br>- **Group**: Có thể là quản trị viên của các nhóm.<br>- **GroupMember**: Thuộc về các nhóm thông qua tư cách thành viên.<br>- **Log**: Tạo nhật ký.<br>- **Consumption**: Ghi lại tiêu thụ.<br>- **ShoppingListTask**: Có thể được giao nhiệm vụ. |

| **UserDevice (Thiết bị người dùng)** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Lưu thông tin thiết bị cho thông báo đẩy.<br>- Ánh xạ mã thông báo FCM với người dùng.<br>- Theo dõi nền tảng (Android/iOS/Web). | - **User**: Thuộc về một người dùng. |

---

## Services

| **CategoryService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Các thao tác CRUD cho Danh mục.<br>- Bắt buộc tên danh mục là duy nhất.<br>- Phân trang và tìm kiếm. | - **Category** Model: Truy cập cơ sở dữ liệu. |

| **ConsumptionService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Lấy thống kê tiêu thụ cho Người dùng hoặc Nhóm.<br>- Tổng hợp dữ liệu tiêu thụ theo Loại thực phẩm và Đơn vị. | - **Consumption** Model: Truy vấn dữ liệu.<br>- **FridgeItem** Model: Lấy chi tiết món.<br>- **Food** Model: Lấy chi tiết thực phẩm.<br>- **Unit** Model: Lấy đơn vị. |

| **CronService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Các tác vụ nền được lên lịch (Kiểm tra hết hạn, Xử lý tiêu thụ).<br>- Kiểm tra hàng ngày các món sắp hết hạn và thông báo.<br>- Tự động xử lý tiêu thụ hàng ngày dựa trên Kế hoạch bữa ăn đã qua (trừ tồn kho tủ lạnh, tạo bản ghi tiêu thụ). | - **FridgeItem** Model: Quản lý tồn kho.<br>- **MealPlan** Model: Lấy kế hoạch đã qua.<br>- **Consumption** Model: Tạo bản ghi tiêu thụ.<br>- **NotificationService**: Gửi cảnh báo.<br>- **Recipe/Ingredient**: Tính toán nguyên liệu cần trừ. |

| **FoodService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Các thao tác CRUD cho Thực phẩm.<br>- Kiểm tra tên thực phẩm duy nhất trong nhóm.<br>- Xử lý xóa hình ảnh khi cập nhật/xóa.<br>- Kiểm soát truy cập (kiểm tra thành viên nhóm). | - **Food** Model: Truy cập CSDL.<br>- **Category** Model: Xác thực.<br>- **Unit** Model: Xác thực.<br>- **Group** Model: Xác thực.<br>- **GroupService**: Xác minh thành viên.<br>- **ImageUtils**: Xử lý tệp hình ảnh. |

| **FridgeService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Quản lý các món trong tủ lạnh (Thêm, Cập nhật, Xóa).<br>- Kiểm tra quyền truy cập.<br>- Kích hoạt thông báo khi có thay đổi. | - **FridgeItem** Model: Truy cập CSDL.<br>- **Food** Model: Lấy dữ liệu.<br>- **GroupService**: Xác minh thành viên.<br>- **NotificationService**: Gửi cập nhật cho nhóm. |

| **GroupService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Quản lý vòng đời Nhóm (Tạo, Đọc).<br>- Quản lý Thành viên Nhóm (Thêm, Xóa).<br>- Xác thực sự tồn tại của người dùng.<br>- Lấy danh sách ID nhóm của người dùng.<br>- Thông báo cho người dùng khi được thêm/xóa. | - **Group** Model: Truy cập CSDL.<br>- **GroupMember** Model: Quản lý thành viên.<br>- **User** Model: Xác thực người dùng.<br>- **NotificationService**: Cảnh báo người dùng. |

| **LogService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Tạo nhật ký kiểm toán.<br>- Lấy nhật ký với bộ lọc và phân trang. | - **Log** Model: Truy cập CSDL.<br>- **User** Model: Lấy chi tiết người dùng.<br>- **ContextUtils**: Lấy người dùng hiện tại. |

| **MealPlanService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Quản lý kế hoạch bữa ăn (Tạo, Cập nhật, Xóa).<br>- Xác thực loại bữa ăn và ngày tháng.<br>- Kiểm tra tồn kho tủ lạnh trước khi tạo kế hoạch (Đủ số lượng nguyên liệu).<br>- Kiểm tra tính nhất quán của đơn vị đo lường.<br>- Thông báo cho nhóm khi kế hoạch thay đổi. | - **MealPlan** Model: Truy cập CSDL.<br>- **FridgeItem** Model: Kiểm tra tồn kho.<br>- **Recipe** Model: Lấy nguyên liệu.<br>- **NotificationService**: Gửi cập nhật. |

| **NotificationService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Gửi thông báo đẩy đến người dùng cụ thể.<br>- Gửi thông báo đa phương thức đến thành viên nhóm.<br>- Quản lý các mã thông báo FCM không hợp lệ. | - **UserDevice** Model: Lấy token.<br>- **GroupMember** Model: Lấy người nhận trong nhóm.<br>- **Group** Model: Lấy người nhận quản trị viên.<br>- **FCMUtils**: Tương tác Firebase. |

| **RecipeService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Quản lý công thức và nguyên liệu (Có giao dịch).<br>- Xử lý hình ảnh công thức (Tải lên, Cập nhật, Xóa).<br>- Thuật toán gợi ý công thức dựa trên đồ trong tủ lạnh.<br>- Thông báo cho nhóm khi công thức thay đổi. | - **Recipe** Model: Truy cập CSDL.<br>- **RecipeIngredient** Model: Quản lý nguyên liệu.<br>- **FridgeItem** Model: Logic gợi ý.<br>- **ImageUtils**: Xử lý hình ảnh.<br>- **NotificationService**: Gửi cập nhật. |

| **ShoppingListService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Quản lý danh sách mua sắm và các nhiệm vụ.<br>- Tạo/Cập nhật/Xóa danh sách và nhiệm vụ.<br>- Kiểm tra quyền truy cập.<br>- Thông báo cho nhóm khi cập nhật danh sách/nhiệm vụ. | - **ShoppingList** Model: Truy cập CSDL.<br>- **ShoppingListTask** Model: Quản lý nhiệm vụ.<br>- **Food** Model: Xác thực.<br>- **User** Model: Xác thực người được giao.<br>- **GroupService**: Xác minh thành viên.<br>- **NotificationService**: Gửi cập nhật. |

| **UnitService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Các thao tác CRUD cho Đơn vị.<br>- Bắt buộc tên đơn vị là duy nhất. | - **Unit** Model: Truy cập CSDL. |

| **UserService** | |
| :--- | :--- |
| **Responsibilities** | **Collaborators** |
| - Đăng ký và xác thực người dùng (Đăng nhập, Làm mới Token).<br>- Xác minh email và đặt lại mật khẩu.<br>- Quản lý hồ sơ người dùng (Cập nhật, Xóa).<br>- Tìm kiếm người dùng. | - **User** Model: Truy cập CSDL.<br>- **JWTUtils**: Tạo token.<br>- **Redis**: Lưu trữ mã (xác minh/đặt lại).<br>- **EmailUtils**: Gửi email.<br>- **LogService**: Nhật ký kiểm toán.<br>- **ImageUtils**: Xử lý ảnh hồ sơ. |
