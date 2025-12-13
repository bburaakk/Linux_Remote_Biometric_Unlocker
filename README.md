# 📱 Linux Remote Biometric Unlocker

**Telefonunuzun parmak izi veya yüz tanıma sensörünü kullanarak Linux bilgisayarınızın kilidini uzaktan açın.**

Bu proje, Flutter ile geliştirilmiş bir mobil uygulama ve Linux bilgisayarınızda çalışan bir Python sunucusundan oluşur. Yerel ağ (Wi-Fi) üzerinden güvenli ve şifreli bir şekilde bilgisayarınızın kilidini açmanızı sağlar.

## ✨ Özellikler

*   **👆 Biyometrik Doğrulama:** Telefonunuzun yerel parmak izi (Fingerprint) veya yüz tanıma (FaceID) sensörlerini kullanır.
*   **🔐 Yüksek Güvenlik:** İletişim, AES-CBC algoritması ile uçtan uca şifrelenir. Her cihaz için özel anahtar (Secret Key) kullanılır.
*   **🖥️ Çoklu Cihaz Desteği:** Birden fazla bilgisayarı tek uygulamadan yönetebilirsiniz.
*   **📝 Bağlantı Logları:** Başarılı ve başarısız kilit açma girişimlerini uygulama içinde görebilirsiniz.
*   **⚡ Hızlı ve Hafif:** Python sunucusu minimum kaynak tüketir.

---

## 🚀 Kurulum Rehberi

Sistemi çalıştırmak için hem bilgisayarınızda hem de telefonunuzda kurulum yapmanız gerekir.

### 1. Bilgisayar Tarafı (Linux Sunucu)

Bilgisayarınızın komutları alabilmesi için Python sunucusunu çalıştırmalısınız.

1.  **Gereksinimleri Yükleyin:**
    Şifreleme kütüphanesini yüklemek için terminalde şu komutu çalıştırın:
    ```bash
    pip install pycryptodome
    ```

2.  **Sunucuyu Ayarlayın:**
    `linux/server.py` dosyasını açın.
    
3.  **Sunucuyu Başlatın:**
    Terminalden script'i çalıştırın:
    ```bash
    python3 linux/server.py
    ```
    *(İpucu: Bu komutu "Başlangıç Uygulamaları"na ekleyerek bilgisayar açıldığında otomatik çalışmasını sağlayabilirsiniz.)*

### 2. Mobil Uygulama Tarafı

1.  Uygulamayı telefonunuza yükleyin ve açın.
2.  Sağ üstteki **Cihazlar** simgesine tıklayın.
3.  **+ (Ekle)** butonuna basın.
4.  Bilgileri girin:
    *   **Cihaz Adı:** Örn: "Ev Bilgisayarım"
    *   **IP Adresi:** Bilgisayarınızın yerel IP adresi (Terminalde `ip addr` yazarak öğrenebilirsiniz).
    *   **Secret Key (Gizli Anahtar):** Buradaki "Yenile" butonuna basarak güvenli bir anahtar oluşturun.
5.  **ÖNEMLİ:** Uygulamada oluşturduğunuz bu **Secret Key**'i kopyalayın ve bilgisayarınızdaki `server.py` dosyasındaki `SECRET_KEY_STRING` alanına yapıştırın. İki taraftaki anahtar AYNI olmalıdır.

---

## 📱 Nasıl Kullanılır?

1.  Bilgisayarınızda `server.py`'ın çalıştığından emin olun.
2.  Telefonda uygulamayı açın.
3.  Eklediğiniz cihazın seçili olduğunu doğrulayın (Yeşil nokta yanmalı).
4.  Ortadaki büyük **Parmak İzi** butonuna basın.
5.  Telefonunuzun biyometrik doğrulamasını geçin.
6.  Bilgisayarınızın kilidi açılacaktır! 🎉

---

## 🛠️ Teknik Detaylar

*   **Dil:** Dart (Flutter) & Python
*   **İletişim:** TCP Socket
*   **Şifreleme:** AES (Advanced Encryption Standard) - CBC Mode
*   **Paketler:**
    *   `local_auth`: Biyometrik doğrulama için.
    *   `encrypt`: AES şifreleme için.
    *   `shared_preferences`: Cihaz bilgilerini telefonda saklamak için.

## ⚠️ Notlar

*   Bilgisayar ve telefon **aynı Wi-Fi ağında** olmalıdır.
*   Eğer bağlantı hatası alırsanız, bilgisayarınızın güvenlik duvarının (Firewall) belirlediğiniz port'a (Varsayılan: 12345) izin verdiğinden emin olun.

---
**Lisans:** MIT
