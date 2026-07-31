# Master Prompt: Actor Detail Screen (Oyuncu Detay Sayfası)

Sen uzman bir Flutter geliştiricisisin. Görevimiz: "Movie Tracker" (Film Takip) uygulamamıza oyunculara (aktörlere) özel bir detay sayfası eklemek. Kullanıcı, film detay sayfasındaki oyuncu listesinde (CastList) bir oyuncunun resmine tıkladığında o oyuncunun detay sayfasına gitmeli. Bu sayfada oyuncunun kısa bir biyografisi ve oynadığı filmler en yüksek puandan (TMDb vote_average) en düşüğe doğru sıralanmış şekilde sergilenmelidir.

## 1. TMDB API Endpoint'leri ve Modeller
Bu özellik için iki yeni TMDB endpoint'ine ihtiyacımız var. (API Key ve Base URL `ApiConfig` içinde mevcut).
1. **Oyuncu Detayları:** `/person/{person_id}` 
   - `biography`, `birthday`, `place_of_birth`, `name`, `profile_path` gibi alanları içerir.
   - Bunu karşılayacak bir `ActorDetail` modeli (ve `fromJson` metodu) oluştur.
2. **Oyuncunun Filmleri:** `/person/{person_id}/movie_credits`
   - Oyuncunun rol aldığı filmleri (`cast` dizisi) döndürür.
   - Dönen filmleri `Movie` modelimizle eşleştirebilirsin (eğer JSON yapısı uygunsa) veya `ActorMovie` adında yeni, hafif bir model oluşturabilirsin. 

## 2. Servis Katmanı (MovieService Güncellemesi)
`lib/services/movie_service.dart` dosyasına iki yeni asenkron metot ekle:
* `fetchActorDetails(int personId)`: Oyuncunun biyografi ve temel bilgilerini getirir.
* `fetchActorMovies(int personId)`: Oyuncunun filmlerini getirir. 
  - **ÖNEMLİ:** Bu metot veriyi çektikten sonra, filmleri `voteAverage` (veya `vote_average`) değerine göre **Büyükten Küçüğe (Descending)** doğru sıralamalıdır (En yüksek puanlı film en üstte).
  - Her iki metot da `ApiException` yönetimine (zaten `_get` metodunda var) uygun olmalıdır.

## 3. UI Tasarımı: ActorDetailScreen
`lib/screens/actor/actor_detail_screen.dart` adında yepyeni bir sayfa tasarla. 
* **Mimari:** `CustomScrollView` ve `SliverAppBar` kullan. `SliverAppBar`'ın arka planında oyuncunun büyük bir fotoğrafı (`profile_path`) yer alsın ve aşağı kaydırıldıkça kararıp küçülsün (Sliver yapısı).
* **Biyografi Bölümü:** Oyuncunun adı, doğum tarihi, yeri ve Biyografi (biography) metni yer almalı. Biyografi çok uzun olabileceği için şık bir tasarım (örneğin "Devamını Oku" butonu veya kısıtlı satır sayısı) düşünebilirsin.
* **Filmografi (Filmler) Bölümü:** Alt kısımda, oyuncunun en yüksek puandan düşüğe doğru sıralanmış filmlerini listele (Bunun için projedeki mevcut `MovieCard` bileşenini bir `SliverGrid` içerisinde kullanabilirsin).

## 4. UI Entegrasyonu: CastList (movie_detail_screen.dart)
Hali hazırda oyuncuları listelediğimiz `lib/widgets/cast_list.dart` bileşeninde değişiklik yap.
* Listelenen her oyuncunun resmini (veya kartını) `GestureDetector` veya `InkWell` ile sarmala.
* Tıklama (onTap) durumunda, `Navigator.push` ile tıklanan oyuncunun ID'sini `ActorDetailScreen`'e parametre olarak geçerek yönlendirme yap.

## 5. Tasarım Dili (Cinematic Noir Theme)
Arayüz, projemizdeki `Cinematic Noir` (CinephileTheme) temasına kusursuz uyum sağlamalı:
* Arka planlar: `CinephileTheme.background`
* Appbar / Resim üstü karartmaları: Uygun gradient ve opacity değerleri
* Metinler: `CinephileTheme.onSurface` (başlıklar) ve `onSurfaceVariant` (biyografi vb.)
* Film ızgarası (Grid) mevcut uygulamanın "Discover" kısmındaki `GridView` tasarımıyla (2 sütunlu, `crossAxisSpacing` ve `childAspectRatio` uyumlu) aynı görünmelidir.

Lütfen bana sırasıyla: Yeni eklenecek Modelleri (`ActorDetail`), `MovieService`'e eklenecek metotları, `CastList` içindeki tıklama (GestureDetector) kodunu ve son olarak yepyeni `ActorDetailScreen` sayfasının tam kodlarını ver. Kodlar üretime hazır (Production-Ready) olmalıdır.
