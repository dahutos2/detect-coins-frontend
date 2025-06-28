import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'config/index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 画面の向きを固定
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detect Coins',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  Image? _predictedImage;
  bool _isLoading = false;
  String? _cash;

  /// ローディング開始
  void _startLoading() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
  }

  /// ローディング終了
  void _endLoading() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  /// サーバーに画像送信
  Future<void> _sendImage() async {
    if (_pickedImage == null) return;
    _startLoading();

    try {
      final bytes = await _pickedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('${AppEnvironment.baseUrl}/trimming'),
        body: json.encode({'post_img': base64Image}),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);
      final imageBase64 = data['result'] as String;
      final cash = data['cash'] as String;

      final predictedBytes = base64Decode(imageBase64);

      setState(() {
        _predictedImage = Image.memory(predictedBytes);
        _cash = cash;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('送信エラー: $e')));
      }
    } finally {
      _endLoading();
    }
  }

  /// 画像選択
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _pickedImage = File(pickedFile.path);
      _predictedImage = null;
      _cash = null;
    });
  }

  /// ズーム用ダイアログ表示
  void _showZoomDialog(Image image) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 3,
              child: image,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '機械学習',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(),
                const SizedBox(height: 16),
                if (_cash != null) _buildCashDisplay(),
              ],
            ),
          ),
          if (_isLoading)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: _buildFixedButtonBar(),
    );
  }

  /// 画像表示エリア
  Widget _buildImageSection() {
    return Column(
      children: [
        _buildImageCard(
          _pickedImage != null ? Image.file(_pickedImage!) : null,
          '画像を選択してください',
          onTap: _pickedImage == null ? _pickImage : null,
        ),
        const SizedBox(height: 12),
        _buildImageCard(
          _predictedImage,
          _isLoading ? '解析中...' : '解析結果がここに表示されます',
          onTap:
              _predictedImage != null
                  ? () => _showZoomDialog(_predictedImage!)
                  : null,
        ),
      ],
    );
  }

  /// 画像カード生成（選択画像・予測画像で共通）
  Widget _buildImageCard(
    Image? image,
    String placeholder, {
    VoidCallback? onTap,
  }) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: GestureDetector(
          onTap: onTap,
          child:
              image == null
                  ? Center(
                    child: Text(
                      placeholder,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                  : FittedBox(fit: BoxFit.contain, child: image),
        ),
      ),
    );
  }

  /// 合計金額表示エリア
  Widget _buildCashDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.monetization_on, color: Colors.teal, size: 28),
          const SizedBox(width: 8),
          Text(
            '合計金額: $_cash',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  /// 固定表示のボタンバー
  Widget _buildFixedButtonBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('画像選択'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sendImage,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('送信'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
