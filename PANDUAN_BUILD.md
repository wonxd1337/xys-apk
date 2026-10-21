# Cara build APK (2 opsi)

Sebelum apa pun: taruh font di `assets/fonts/MadeEvolveSans-Medium.otf`
(opsional: gambar latar di `assets/images/bg.jpg`).
Lisensi font "personal use" -> kalau pakai GitHub, buat repo **Private**.

## Opsi A: Termux + GitHub Actions (semua dari HP)
1. Buat repo kosong (Private) di github.com, buat Personal Access Token
   (Settings > Developer settings > Tokens classic, centang `repo` dan `workflow`).
2. Di Termux:
   pkg update && pkg install git unzip
   cd ~ && unzip /sdcard/Download/deoxys_tahap2.zip && cd deoxys_dashboard
   git init -b main
   git add . && git commit -m "deoxys"
   git remote add origin https://github.com/USERNAME/NAMAREPO.git
   git push -u origin main      # password = token tadi
3. Buka repo > tab Actions > "Build APK" > tunggu +-6 menit.
4. Buka run yang selesai > Artifacts > deoxys-apk > download > ekstrak > install APK.
5. Update kode berikutnya: ganti file, lalu
   git add . && git commit -m "update" && git push
   (atau jalankan manual: Actions > Build APK > Run workflow)

## Opsi B: PC Windows
1. Pasang Flutter SDK versi 3.35.x (BUKAN yang terbaru, lihat catatan di bawah) dan Android Studio (SDK + cmdline-tools), jalankan `flutter doctor`.
2. Di folder proyek:
   flutter create --org com.tew --project-name deoxys_dashboard --platforms=android .
   (jangan timpa lib/ dan pubspec.yaml; kalau ditanya, pilih tidak)
3. Edit android/app/src/main/AndroidManifest.xml:
   - tambah <uses-permission android:name="android.permission.INTERNET"/> di atas <application>
   - tambah android:usesCleartextTraffic="true" di tag <application>
4. flutter pub get
5. flutter build apk --release
   Hasil: build/app/outputs/flutter-apk/app-release.apk

## Pertama kali dibuka
Menu > Pengaturan > isi URL server (folder berisi api.php) > Simpan.

## Catatan versi Flutter
Paket font_awesome_flutter 10.x belum cocok dengan Flutter terbaru (IconData jadi final). Karena itu proyek ini dikunci ke Flutter 3.35.x, baik di GitHub Actions maupun di PC.
