/**
 * デモ用心拍数シミュレーションスクリプト
 *
 * 機能:
 * - 3秒に1回、実際の人間の鼓動に寄せたBPMをRealtime Databaseに書き込む
 * - 複数ユーザーに対して同時に動作可能
 * - 自然な変動を持つBPM生成（安静時: 60-80bpm、やや興奮時: 80-100bpm）
 */

const admin = require('firebase-admin');

// サービスアカウントキーを配置
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://heart-beat-23158-default-rtdb.asia-southeast1.firebasedatabase.app'
});

const database = admin.database();

/**
 * 実際の人間の心拍数に寄せたBPMを生成
 * - ベースBPM: 70bpm (安静時の平均)
 * - 変動幅: ±10bpm
 * - ゆっくりとした変化を実現するため、前回の値を考慮
 */
class HeartbeatSimulator {
  constructor(userId, baseBpm = 90, variationRange = 10) {
    this.userId = userId;
    this.baseBpm = baseBpm;
    this.variationRange = variationRange;
    this.currentBpm = baseBpm;
    this.targetBpm = baseBpm;
    this.updateCounter = 0;
  }

  /**
   * 次のBPM値を生成
   * - 10回に1回、新しい目標BPMを設定
   * - それ以外は現在のBPMから目標BPMに徐々に近づける
   */
  getNextBpm() {
    // 10回に1回、新しい目標を設定（約30秒に1回）
    if (this.updateCounter % 10 === 0) {
      this.targetBpm = this.baseBpm + (Math.random() - 0.5) * 2 * this.variationRange;
      this.targetBpm = Math.round(this.targetBpm);
    }

    // 現在のBPMを目標に向けて徐々に変化させる
    const diff = this.targetBpm - this.currentBpm;
    const change = diff * 0.2 + (Math.random() - 0.5) * 2; // 20%近づける + 小さなランダム変動
    this.currentBpm += change;

    // BPMを現実的な範囲に制限（50-120bpm）
    this.currentBpm = Math.max(50, Math.min(120, Math.round(this.currentBpm)));

    this.updateCounter++;
    return this.currentBpm;
  }

  /**
   * Realtime Databaseに心拍数を書き込む
   */
  async updateHeartbeat() {
    const bpm = this.getNextBpm();
    const timestamp = Date.now();

    try {
      const ref = database.ref(`live_heartbeats/${this.userId}`);

      // 既存のconnections値を取得
      const snapshot = await ref.child('connections').once('value');
      const currentConnections = snapshot.val() || 0;

      await ref.update({
        bpm: bpm,
        timestamp: timestamp
      });
      console.log(`[${new Date().toISOString()}] User ${this.userId}: ${bpm} bpm (connections: ${currentConnections})`);
    } catch (error) {
      console.error(`Error updating heartbeat for ${this.userId}:`, error);
    }
  }

  /**
   * 接続開始時にconnectionsをインクリメント
   */
  async incrementConnections() {
    try {
      const ref = database.ref(`live_heartbeats/${this.userId}/connections`);
      const snapshot = await ref.once('value');
      const currentConnections = snapshot.val() || 0;
      await ref.set(currentConnections + 1);
      console.log(`[${this.userId}] Connections incremented: ${currentConnections + 1}`);
    } catch (error) {
      console.error(`Error incrementing connections for ${this.userId}:`, error);
    }
  }

  /**
   * 接続終了時にconnectionsをデクリメント
   */
  async decrementConnections() {
    try {
      const ref = database.ref(`live_heartbeats/${this.userId}/connections`);
      const snapshot = await ref.once('value');
      const currentConnections = snapshot.val() || 0;
      const newConnections = Math.max(0, currentConnections - 1);
      await ref.set(newConnections);
      console.log(`[${this.userId}] Connections decremented: ${newConnections}`);
    } catch (error) {
      console.error(`Error decrementing connections for ${this.userId}:`, error);
    }
  }
}

/**
 * 複数ユーザーの心拍数をシミュレート
 * @param {string[]} userIds - シミュレート対象のユーザーIDリスト
 * @param {number} intervalSeconds - 更新間隔（秒）
 */
async function startSimulation(userIds, intervalSeconds = 3) {
  console.log(`Starting heartbeat simulation for ${userIds.length} users...`);
  console.log(`Update interval: ${intervalSeconds} seconds`);
  console.log('Press Ctrl+C to stop\n');

  // 各ユーザーのシミュレーターを作成
  const simulators = userIds.map((userId, index) => {
    // ユーザーごとに少し異なるベースBPMを設定
    const baseBpm = 65 + index * 5; // 65, 70, 75, 80...
    return new HeartbeatSimulator(userId, baseBpm);
  });

  // 開始時にconnectionsをインクリメント
  console.log('Incrementing connections...');
  const incrementPromises = simulators.map(sim => sim.incrementConnections());
  await Promise.all(incrementPromises);
  console.log('');

  // 定期的に更新
  const interval = setInterval(async () => {
    const updatePromises = simulators.map(sim => sim.updateHeartbeat());
    await Promise.all(updatePromises);
  }, intervalSeconds * 1000);

  // Ctrl+Cでの終了処理
  process.on('SIGINT', async () => {
    console.log('\n\nStopping simulation...');
    clearInterval(interval);

    // connectionsをデクリメント
    console.log('Decrementing connections...');
    const decrementPromises = simulators.map(sim => sim.decrementConnections());
    await Promise.all(decrementPromises);

    // 最後にすべてのユーザーの心拍データを削除（オプション）
    // console.log('Cleaning up heartbeat data...');
    // const deletePromises = userIds.map(userId =>
    //   database.ref(`live_heartbeats/${userId}`).remove()
    // );
    await Promise.all(deletePromises);

    console.log('Cleanup complete!');
    process.exit(0);
  });
}

// ========================================
// スクリプト実行
// ========================================

// シミュレート対象のユーザーIDを設定
// 実際のユーザーIDに置き換えてください
const userIds = [
  // 'Io3ANwnrAHTMU3PQPQBV4oLXC2t1',
  'EKra5EuFx1cvy8d2LKV0gh2DfQE3',
  // 'demo-user-3'
];

// 更新間隔（秒）
const UPDATE_INTERVAL = 3;

startSimulation(userIds, UPDATE_INTERVAL)
  .catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
