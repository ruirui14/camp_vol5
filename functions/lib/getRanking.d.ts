/**
 * Cloud Functions - Get Ranking with Cache
 *
 * ランキングデータをオンメモリキャッシュ付きで取得
 * Upstash Redisへの読み取り回数を削減するため、5分間キャッシュ
 */
import * as functions from "firebase-functions";
/**
 * ランキング取得（キャッシュ付き）
 * HTTPS関数として外部から呼び出し可能
 */
export declare const getRanking: functions.HttpsFunction;
//# sourceMappingURL=getRanking.d.ts.map