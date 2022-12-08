export function urlToDomain(url) {
  const splitHost = new URL(url).hostname.split('.');
  return [splitHost[splitHost.length - 2], splitHost[splitHost.length - 1]].join('.');
}