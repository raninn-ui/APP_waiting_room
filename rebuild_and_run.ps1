# PowerShell script to rebuild and run the Flutter app
Write-Host "🧹 Step 1: Cleaning Flutter build..." -ForegroundColor Cyan
flutter clean

Write-Host "`n🧹 Step 2: Cleaning Gradle cache..." -ForegroundColor Cyan
cd android
./gradlew clean
cd ..

Write-Host "`n📦 Step 3: Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host "`n🔨 Step 4: Building APK..." -ForegroundColor Cyan
flutter build apk --debug

Write-Host "`n🚀 Step 5: Installing and running app..." -ForegroundColor Cyan
flutter run -d emulator-5554 --target=lib/main_test.dart

Write-Host "`n✅ Done!" -ForegroundColor Green

