# Master Prompt: Movie Comments Feature Implementation

Sen uzman bir Flutter ve Firebase geliştiricisisin. Görevimiz: "Movie Tracker" (Film Takip) uygulamamıza kullanıcıların filmlere yorum (review) yapabilmesi özelliğini eklemek. Uygulama artık sosyal bir ağ değil, tamamen bireysel kullanıma yönelik ancak kullanıcılar girdikleri filmlerde diğer kullanıcıların veya kendi yaptıkları yorumları görebilmeli ve yeni yorum ekleyebilmelidir.

## 1. Veritabanı (Firestore) Mimarisi
Yorumları saklamak için Firestore üzerinde bir koleksiyon yapısı tasarlamanı istiyorum.
* Öneri Yapı: `movies/{movieId}/comments/{commentId}` 
* Veya kök koleksiyon: `comments` (içerisinde `movieId`, `userId`, `userName`, `text`, `createdAt` gibi alanlar barındıran dokümanlar).
* Lütfen en optimize okuma/yazma yapısını seç ve bunu `Comment` (veya `Review`) adlı bir Dart modeli ile eşleştir (örn: `lib/models/comment.dart`). Model içerisinde `fromJson` ve `toMap` metotları bulunmalı.

## 2. Servis Katmanı (CommentService)
`lib/services/comment_service.dart` adında bir servis oluştur. Bu servis şunları yapabilmeli:
* **Yorum Ekleme:** Belirli bir filme yeni bir yorum (metin) ekleme. (Kullanıcının `uid` ve `displayName` bilgisini Firebase Auth üzerinden almalı).
* **Yorumları Getirme:** Belirli bir `movieId`'ye ait yorumları zamana göre (en yeni en üstte) sıralı olarak getiren bir `Stream<List<Comment>>` veya sayfalama destekli bir metot.

## 3. UI Entegrasyonu (MovieDetailScreen)
Yorum yapma ve okuma alanı, halihazırda var olan `MovieDetailScreen` sayfasının alt kısmına (oyuncular listesinin altına) eklenecek.
* **Yorumları Listeleme:** Çekilen yorumları şık bir liste (veya ListView.builder) içerisinde göster. Her yorumda kullanıcının adı, yorum metni ve yorum tarihi (örn. '2 gün önce', '12 Tem 2026') yer alsın.
* **Yorum Ekleme Alanı:** Kullanıcının yorum yazabileceği bir `TextField` ve "Gönder" butonu içeren bir alt alan veya tıklandığında açılan bir "Yorum Ekle" (BottomSheet/Dialog) ekranı tasarla.

## 4. Tasarım Dili (Cinematic Noir Theme)
Uygulamada "Cinematic Noir" adlı karanlık ve şık bir tema kullanıyoruz. Geliştireceğin arayüz bu temaya birebir uymalı:
* Arka planlar: `CinephileTheme.surfaceContainer` veya `surfaceContainerHigh`
* Metinler: `CinephileTheme.onSurface` (başlıklar) ve `onSurfaceVariant` (detaylar/tarihler).
* Butonlar/Aksanlar: `CinephileTheme.primaryContainer`
* Yorumlar arasında çok ince, yarı saydam çizgiler (`Colors.white.withAlpha(15)` gibi) veya ayrık (marginli) kart tasarımları kullanabilirsin.

## 5. Hata Yönetimi ve Edge Caseler
* Kullanıcı giriş yapmamışsa (ki uygulamada genelde girmiş olur ama güvenlik amaçlı) veya internet yoksa uygun hata mesajları (SnackBar).
* Yorum listesi boşsa şık bir "İlk yorumu sen yap!" (Empty State) tasarımı.
* Yüklenme durumlarında, standart CircularProgressIndicator veya Shimmer efekti.

Lütfen bana ilk olarak `Comment` modelini, sonra `CommentService` kodlarını, son olarak da `MovieDetailScreen` içerisine eklenecek ilgili UI widget'larını (gerekirse ayrı bir `MovieCommentsWidget` dosyası olarak) ver. Kodların "Production-Ready" (üretime hazır) ve hatasız olmasına dikkat et.
