class SupabaseConfig {
  // 🔑 Supabase Dashboard → Settings → API'den alacaksınız
  
  // ⚠️ Project URL şu formatta olmalı: https://xxxxx.supabase.co
  // Dashboard'da "Project URL" yazan yeri kopyalayın
  static const String supabaseUrl = 'https://xstoytqljevmudhneiwf.supabase.co';
  
  // ⚠️ "anon public" key'i kopyalayın (eyJ... ile başlar, çok uzundur)
  // "service_role" key'i KULLANMAYIN!
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzdG95dHFsamV2bXVkaG5laXdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3NTM0MjIsImV4cCI6MjA3OTMyOTQyMn0.Qu_gHpJBaThiGYLmrBUf8RArWEbJQH8YqPfseMB5eyM';
  
  // Doğru key formatı:
  // 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...'
}
