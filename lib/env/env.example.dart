/// 🔐 Supabase Yapılandırma Dosyası
/// 
/// KURULUM:
/// 1. Bu dosyayı aynı klasörde `env.dart` olarak kopyalayın
/// 2. Aşağıdaki değerleri kendi Supabase bilgilerinizle değiştirin
/// 3. env.dart dosyası .gitignore'a eklenmiştir, GitHub'a yüklenmez
/// 
/// Supabase bilgilerinizi https://supabase.com/dashboard adresinden alabilirsiniz.

class Env {
  /// Supabase Project URL
  /// Örnek: https://xxxxx.supabase.co
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  
  /// Supabase Anon/Public Key
  /// Project Settings > API > anon public
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
}
