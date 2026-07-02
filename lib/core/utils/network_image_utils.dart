/// Strips the query string and fragment so presigned URLs (e.g. S3 with
/// rotating signatures) resolve to the same logical asset.
String stableNetworkImageCacheKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  return uri.replace(query: '', fragment: '').toString();
}

bool isSameNetworkImage(String? a, String? b) {
  if (a == null || b == null) return a == b;
  return stableNetworkImageCacheKey(a) == stableNetworkImageCacheKey(b);
}
