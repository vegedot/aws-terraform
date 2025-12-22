/**
 * Lambda@Edge - Viewer Request
 *
 * CloudFrontがビューワー（ブラウザ）からリクエストを受信した後、
 * キャッシュを確認する前に実行される
 *
 * ユースケース:
 * - リクエストヘッダーの追加/変更
 * - URLリライト
 * - A/Bテスト
 * - 認証チェック
 */

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // 例1: セキュリティヘッダーの追加
  headers['x-custom-header'] = [{
    key: 'X-Custom-Header',
    value: 'CloudFront-Lambda-Edge'
  }];

  // 例2: URLリライト（/old-path -> /new-path）
  if (request.uri === '/old-path') {
    request.uri = '/new-path';
  }

  // 例3: デフォルトのindex.htmlを追加
  if (request.uri.endsWith('/')) {
    request.uri += 'index.html';
  }

  // 例4: A/Bテスト（50/50）
  const random = Math.random();
  if (random < 0.5) {
    headers['x-experiment-variant'] = [{
      key: 'X-Experiment-Variant',
      value: 'A'
    }];
  } else {
    headers['x-experiment-variant'] = [{
      key: 'X-Experiment-Variant',
      value: 'B'
    }];
  }

  return request;
};
