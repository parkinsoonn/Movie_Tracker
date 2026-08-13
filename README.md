# Film Uygulaması (Movie Tracker)

Kullanıcıların filmleri keşfedebileceği, kendi izleme listelerini (watchlist) oluşturabileceği, filmler hakkında yorum yapabileceği ve profillerini yönetebileceği kapsamlı bir Flutter mobil uygulamasıdır.

## 🚀 Özellikler

- **Kullanıcı Kimlik Doğrulama:** Firebase Authentication ile güvenli üyelik ve giriş işlemleri.
- **Film ve Oyuncu Keşfi:** Güncel ve popüler filmleri, detaylarını ve oyuncu kadrosunu görüntüleme.
- **İzleme Listesi (Watchlist):** Beğendiğiniz veya daha sonra izlemek istediğiniz filmleri kişisel listenize ekleme ve yönetme.
- **Yorum Sistemi:** Filmler hakkında yorum yapabilme ve diğer kullanıcıların yorumlarını okuyabilme (Firestore entegrasyonu).
- **Profil Yönetimi:** Kullanıcı bilgilerini düzenleme ve profil fotoğrafı yükleme/güncelleme (Image Picker & Firebase Storage).
- **Modern ve Akıcı Arayüz:** Google Fonts ve zengin UI bileşenleri ile güçlendirilmiş, kullanıcı dostu deneyim.

## 🛠️ Kullanılan Teknolojiler ve Paketler

- **Geliştirme Ortamı:** Flutter & Dart
- **Backend / Veritabanı:** Firebase (Authentication, Cloud Firestore, Firebase Storage)
- **Ağ İstekleri:** `http` paketi (Film verilerini çekmek için)
- **Yardımcı Paketler:** 
  - `google_fonts` (Özel tipografi)
  - `image_picker` (Profil fotoğrafı seçimi)
  - `cupertino_icons` (iOS stili ikonlar)

## 📱 Ekranlar
- **Giriş / Kayıt Ekranı (Auth):** E-posta ve şifre ile giriş/kayıt sistemi.
- **Ana Ekran (Home):** Trend olan ve öne çıkan filmlerin listelendiği ana sayfa.
- **Film Detay (Movie):** Filmin afişi, konusu, oyuncuları ve yorumların bulunduğu detay sayfası.
- **Oyuncu (Actor):** Oyuncuların biyografileri ve oynadıkları diğer filmler.
- **İzleme Listesi (Watchlist):** Kullanıcının kaydettiği filmlerin bulunduğu liste ekranı.
- **Profil (Profile):** Kullanıcı bilgileri ve uygulama ayarlarının bulunduğu kişisel ekran.

## ⚙️ Kurulum ve Çalıştırma

Projeyi yerel bilgisayarınızda çalıştırmak için aşağıdaki adımları izleyin:

1. **Repoyu Klonlayın:**
   ```bash
   git clone <repo-url>
   ```

2. **Proje Dizinine Gidin:**
   ```bash
   cd Movie_Tracker-main
   ```

3. **Bağımlılıkları Yükleyin:**
   ```bash
   flutter pub get
   ```

4. **Firebase Yapılandırması:**
   - Proje Firebase kullanmaktadır ancak güvenlik nedeniyle Firebase yapılandırma dosyaları repoda yer almayabilir.
   - [Firebase Console](https://console.firebase.google.com/) üzerinden kendi projenizi oluşturun.
   - **FlutterFire CLI** kullanarak veya manuel olarak `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını projenize ekleyin.
   - Firebase Authentication, Firestore ve Storage servislerini aktifleştirdiğinizden emin olun.

5. **Uygulamayı Başlatın:**
   ```bash
   flutter run
   ```

## 📝 Lisans
Bu proje geliştirme aşamasındadır. İstediğiniz gibi kullanabilir ve geliştirebilirsiniz.
