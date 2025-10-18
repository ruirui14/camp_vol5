const admin = require('firebase-admin');

// サービスアカウントキーを配置
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function deleteAllUsers(nextPageToken) {
  // 最大1000ユーザーずつ取得
  const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
  
  const uids = listUsersResult.users.map(user => user.uid);
  
  if (uids.length > 0) {
    console.log(`Deleting ${uids.length} users...`);
    
    // 一括削除
    await admin.auth().deleteUsers(uids);
    
    console.log(`Successfully deleted ${uids.length} users`);
  }
  
  // 次のページがあれば再帰的に削除
  if (listUsersResult.pageToken) {
    await deleteAllUsers(listUsersResult.pageToken);
  } else {
    console.log('All users deleted!');
  }
}

// 実行
deleteAllUsers()
  .then(() => {
    console.log('Complete!');
    process.exit(0);
  })
  .catch(error => {
    console.error('Error:', error);
    process.exit(1);
  });
