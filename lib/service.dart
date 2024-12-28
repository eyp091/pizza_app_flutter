import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:io';

Future<void> performAllTasks() async {
  await fetchProductNames();
  List<String> imageUrls = await fetchImageUrls();
  String directoryPath = 'resimler';
  await downloadImages(imageUrls, directoryPath);
}

Future<void> fetchProductNames() async {
  // Web sitesinden HTML içeriğini al
  final response = await http.get(Uri.parse('https://www.terrapizza.com.tr/l/pizzalar'));

  if (response.statusCode == 200) {
    // HTML içeriğini işle
    final document = parser.parse(response.body);

    // Belirli etikete sahip tüm öğeleri seç
    var h3Elements = document.querySelectorAll('h3.category-product__details__title.tpf');
    var spanElements = document.querySelectorAll('.category-product__details__price.new.tpf .integer');

    // Verileri bir string değişkeninde topla
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < h3Elements.length; i++) {
      String productName = h3Elements[i].text.trim();
      String productPrice = spanElements[i].text.trim();
      buffer.writeln("Ürün Adı: $productName");
      buffer.writeln("Ürün Fiyatı: $productPrice");
    }

    // Dosyaya kaydet
    await _writeToFile(buffer.toString());
  } else {
    print("Ürün adları yüklenemedi: ${response.statusCode}");
  }
}

Future<void> _writeToFile(String data) async {
  try {
    // Çalışma dizinini al
    final directory = Directory.current;

    // 'resimler' klasörünü oluştur
    final path = '${directory.path}/resimler';
    final directoryExists = await Directory(path).exists();
    if (!directoryExists) {
      await Directory(path).create(recursive: true);
    }

    // Dosya yolunu belirle
    final file = File('$path/products.txt');

    // Dosyayı oluştur ve verileri yaz
    await file.writeAsString(data, mode: FileMode.write);

    print('Veriler kaydedildi: ${file.path}');
  } catch (e) {
    print('Dosya yazma hatası: $e');
  }
}


Future<List<String>> fetchImageUrls() async {
  List<String> imageUrls = [];

  final response = await http.get(Uri.parse('https://www.terrapizza.com.tr/l/pizzalar'));
  if (response.statusCode == 200) {
    final document = parser.parse(response.body);

    var divElements = document.querySelectorAll('.category-product__image');
    for (var divElement in divElements) {
      var imgElement = divElement.querySelector('img');
      if (imgElement != null) {
        var srcAttribute = imgElement.attributes['src'];
        if (srcAttribute != null) {
          String imageUrl = srcAttribute;
          imageUrls.add(imageUrl);
        } else {
          print('Liste Boş');
        }
      }
    }
  } else {
    print("Resim URL'leri yüklenemedi: ${response.statusCode}");
  }
  return imageUrls;
}

Future<void> downloadImages(List<String> imageUrls, String directoryPath) async {
  for (var url in imageUrls) {
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Resmi kaydetmek için dosya yolu
        var fileName = 'image_${imageUrls.indexOf(url) + 1}.png';
        var filePath = '$directoryPath/$fileName';

        // Dosyanın zaten var olup olmadığını kontrol et
        var file = File(filePath);
        if (file.existsSync()) {
          print('Hata: Dosya zaten var - $filePath');
          continue; // Dosya zaten varsa işlemi atla ve bir sonraki resme geç
        }

        // Dosyayı oluştur ve resmi kaydet
        await file.writeAsBytes(response.bodyBytes);
        print('Resim indirildi: $filePath');
      } else {
        print('Hata: ${response.statusCode} - $url indirilemedi');
      }
    } catch (e) {
      print('Hata: $e');
    }
  }
}
