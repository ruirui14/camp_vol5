/**
 * Cloud Functions - Get Ranking with Cache
 *
 * ランキングデータをオンメモリキャッシュ付きで取得
 * Upstash Redisへの読み取り回数を削減
 * ランキングは毎時59分に更新されるため、時が変わったらキャッシュを無効化
 */
import * as functions from "firebase-functions";
/**
 * ランキング取得（キャッシュ付き）
 * HTTPS関数として外部から呼び出し可能
 */
export declare const getRanking: functions.HttpsFunction;
//# sourceMappingURL=getRanking.d.ts.map