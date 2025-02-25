import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart'; // Dùng khi tích hợp quét mã thực tế

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initDB();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Widget gốc của ứng dụng
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phần mềm quản lý kho',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: LoginPage(),
      routes: {
        '/home': (context) => HomePage(),
        '/product': (context) => ProductDeclarationPage(),
        '/import': (context) => InventoryInputPage(),
        '/export': (context) => InventoryOutputPage(),
        '/report': (context) => InventoryReportPage(),
      },
    );
  }
}

// 1. Màn hình đăng nhập với chức năng "Ghi nhớ đăng nhập"
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadLogin();
  }

  // Tải thông tin đăng nhập đã lưu
  _loadLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('rememberMe') ?? false;
    if (remember) {
      String username = prefs.getString('username') ?? '';
      String password = prefs.getString('password') ?? '';
      _usernameController.text = username;
      _passwordController.text = password;
      _rememberMe = true;
      // Chuyển thẳng vào trang chính (đối với demo)
      Navigator.pushReplacementNamed(this.context, '/home');
    }
  }

  _login() async {
    // Ở đây demo đơn giản: chỉ cần có dữ liệu thì được đăng nhập
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      if (_rememberMe) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', true);
        await prefs.setString('username', _usernameController.text);
        await prefs.setString('password', _passwordController.text);
      }
      Navigator.pushReplacementNamed(this.context, '/home');
    } else {
      ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin đăng nhập")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đăng nhập"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Tên đăng nhập"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (val) {
                    setState(() {
                      _rememberMe = val ?? false;
                    });
                  },
                ),
                Text("Ghi nhớ đăng nhập")
              ],
            ),
            ElevatedButton(
              onPressed: _login,
              child: Text("Đăng nhập"),
            )
          ],
        ),
      ),
    );
  }
}

// 2. Trang chủ: Menu chính của phần mềm
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý kho"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("Khai báo sản phẩm"),
            onTap: () => Navigator.pushNamed(context, '/product'),
          ),
          ListTile(
            title: Text("Nhập hàng (Kho)"),
            onTap: () => Navigator.pushNamed(context, '/import'),
          ),
          ListTile(
            title: Text("Xuất hàng (Kho)"),
            onTap: () => Navigator.pushNamed(context, '/export'),
          ),
          ListTile(
            title: Text("Báo cáo tồn kho"),
            onTap: () => Navigator.pushNamed(context, '/report'),
          ),
        ],
      ),
    );
  }
}

// 3. Trang khai báo sản phẩm
class ProductDeclarationPage extends StatefulWidget {
  @override
  _ProductDeclarationPageState createState() => _ProductDeclarationPageState();
}
class _ProductDeclarationPageState extends State<ProductDeclarationPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  _saveProduct() async {
    String name = _nameController.text;
    String description = _descController.text;
    if (name.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text("Tên sản phẩm không được để trống")));
      return;
    }
    // Tạo mã QR đơn giản dựa trên tên sản phẩm và thời gian hiện tại
    String qrCode = "$name-${DateTime.now().millisecondsSinceEpoch}";
    await DatabaseHelper.instance
        .insertProduct({'name': name, 'description': description, 'qrCode': qrCode});
    ScaffoldMessenger.of(this.context)
        .showSnackBar(SnackBar(content: Text("Sản phẩm đã được khai báo")));
    _nameController.clear();
    _descController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Khai báo sản phẩm"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Tên sản phẩm"),
            ),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: "Mô tả sản phẩm"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProduct,
              child: Text("Lưu sản phẩm"),
            )
          ],
        ),
      ),
    );
  }
}

// 4. Trang nhập hàng (cập nhật tồn kho)
class InventoryInputPage extends StatefulWidget {
  @override
  _InventoryInputPageState createState() => _InventoryInputPageState();
}
class _InventoryInputPageState extends State<InventoryInputPage> {
  final _qrController = TextEditingController();
  final _quantityController = TextEditingController();

  // Giả lập chức năng quét mã QR
  _scanQRCode() async {
    // Ở đây, tích hợp thư viện quét mã thực tế sẽ sử dụng QRView, camera,...
    // Với demo, ta gán giá trị mẫu:
    setState(() {
      _qrController.text = "sample-product-qr-code";
    });
  }

  _importGoods() async {
    String qrCode = _qrController.text;
    int quantity = int.tryParse(_quantityController.text) ?? 0;
    if (qrCode.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
          content: Text("Vui lòng nhập mã sản phẩm và số lượng hợp lệ")));
      return;
    }
    // Tìm sản phẩm theo mã QR
    Map<String, dynamic>? product =
        await DatabaseHelper.instance.getProductByQR(qrCode);
    if (product == null) {
      ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text("Sản phẩm không tồn tại")));
      return;
    }
    // Cập nhật tồn kho
    await DatabaseHelper.instance.importGoods(product['id'], quantity);
    ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text("Nhập hàng thành công")));
    _qrController.clear();
    _quantityController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nhập hàng"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _qrController,
              decoration: InputDecoration(labelText: "Mã sản phẩm (QR Code)"),
            ),
            ElevatedButton(
              onPressed: _scanQRCode,
              child: Text("Quét mã QR"),
            ),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: "Số lượng nhập"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _importGoods,
              child: Text("Xác nhận nhập hàng"),
            )
          ],
        ),
      ),
    );
  }
}

// 5. Trang xuất hàng (trừ tồn kho)
class InventoryOutputPage extends StatefulWidget {
  @override
  _InventoryOutputPageState createState() => _InventoryOutputPageState();
}
class _InventoryOutputPageState extends State<InventoryOutputPage> {
  final _qrController = TextEditingController();
  final _quantityController = TextEditingController();

  // Giả lập quét mã QR
  _scanQRCode() async {
    setState(() {
      _qrController.text = "sample-product-qr-code";
    });
  }

  _exportGoods() async {
    String qrCode = _qrController.text;
    int quantity = int.tryParse(_quantityController.text) ?? 0;
    if (qrCode.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
          content: Text("Vui lòng nhập mã sản phẩm và số lượng hợp lệ")));
      return;
    }
    Map<String, dynamic>? product =
        await DatabaseHelper.instance.getProductByQR(qrCode);
    if (product == null) {
      ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text("Sản phẩm không tồn tại")));
      return;
    }
    bool success = await DatabaseHelper.instance.exportGoods(product['id'], quantity);
    if (success) {
      ScaffoldMessenger.of(this.context)
          .showSnackBar(SnackBar(content: Text("Xuất hàng thành công")));
    } else {
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
          content: Text("Xuất hàng thất bại: số lượng không đủ")));
    }
    _qrController.clear();
    _quantityController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Xuất hàng"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _qrController,
              decoration: InputDecoration(labelText: "Mã sản phẩm (QR Code)"),
            ),
            ElevatedButton(
              onPressed: _scanQRCode,
              child: Text("Quét mã QR"),
            ),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: "Số lượng xuất"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _exportGoods,
              child: Text("Xác nhận xuất hàng"),
            )
          ],
        ),
      ),
    );
  }
}

// 6. Trang báo cáo tồn kho
class InventoryReportPage extends StatefulWidget {
  @override
  _InventoryReportPageState createState() => _InventoryReportPageState();
}
class _InventoryReportPageState extends State<InventoryReportPage> {
  List<Map<String, dynamic>> _report = [];

  _loadReport() async {
    List<Map<String, dynamic>> data = await DatabaseHelper.instance.getInventoryReport();
    setState(() {
      _report = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Báo cáo tồn kho"),
      ),
      body: ListView.builder(
        itemCount: _report.length,
        itemBuilder: (context, index) {
          var item = _report[index];
          return ListTile(
            title: Text("Sản phẩm: ${item['name']}"),
            subtitle: Text("Tồn: ${item['quantity']}"),
          );
        },
      ),
    );
  }
}

// 7. Lớp DatabaseHelper quản lý SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'warehouse.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // Tạo bảng sản phẩm
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        qrCode TEXT UNIQUE
      )
    ''');
    // Tạo bảng tồn kho: mỗi sản phẩm có số lượng tồn
    await db.execute('''
      CREATE TABLE inventory(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        quantity INTEGER,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');
    // Tạo bảng giao dịch (nhập/xuất)
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        type TEXT,
        quantity INTEGER,
        date TEXT,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');
  }

  // Thêm sản phẩm mới
  Future<int> insertProduct(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = await db.insert('products', row);
    // Khởi tạo tồn kho cho sản phẩm với số lượng 0
    await db.insert('inventory', {'productId': id, 'quantity': 0});
    return id;
  }

  // Lấy sản phẩm theo mã QR
  Future<Map<String, dynamic>?> getProductByQR(String qrCode) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results =
        await db.query('products', where: 'qrCode = ?', whereArgs: [qrCode]);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Nhập hàng: tăng số lượng tồn kho
  Future<void> importGoods(int productId, int quantity) async {
    Database db = await instance.database;
    await db.rawUpdate(
        'UPDATE inventory SET quantity = quantity + ? WHERE productId = ?',
        [quantity, productId]);
    await db.insert('transactions', {
      'productId': productId,
      'type': 'in',
      'quantity': quantity,
      'date': DateTime.now().toIso8601String()
    });
  }

  // Xuất hàng: giảm số lượng tồn kho nếu đủ hàng
  Future<bool> exportGoods(int productId, int quantity) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db
        .query('inventory', where: 'productId = ?', whereArgs: [productId]);
    if (results.isNotEmpty) {
      int currentQuantity = results.first['quantity'];
      if (currentQuantity >= quantity) {
        await db.rawUpdate(
            'UPDATE inventory SET quantity = quantity - ? WHERE productId = ?',
            [quantity, productId]);
        await db.insert('transactions', {
          'productId': productId,
          'type': 'out',
          'quantity': quantity,
          'date': DateTime.now().toIso8601String()
        });
        return true;
      }
    }
    return false;
  }

  // Lấy báo cáo tồn kho: kết hợp giữa bảng sản phẩm và tồn kho
  Future<List<Map<String, dynamic>>> getInventoryReport() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT p.name, i.quantity FROM products p
      JOIN inventory i ON p.id = i.productId
    ''');
    return results;
  }
}
