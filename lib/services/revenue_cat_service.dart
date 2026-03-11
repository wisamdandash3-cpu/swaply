/// RevenueCat: تهيئة وربط المستخدم. على iOS/Android يستخدم purchases_flutter، على الويب لا يعمل شيء.
library;

export 'revenue_cat_service_stub.dart'
  if (dart.library.io) 'revenue_cat_service_io.dart';
