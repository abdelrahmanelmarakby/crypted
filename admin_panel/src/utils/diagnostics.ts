// Diagnostic utilities to help debug data issues

import { collection, getDocs, query, limit } from 'firebase/firestore';
import { db } from '@/config/firebase';
import { COLLECTIONS } from '@/utils/constants';

/**
 * Check if we can read from Firebase collections
 */
export async function runDiagnostics() {
  console.log('🔍 Running Firebase Diagnostics...\n');

  const collections = [
    { name: 'users', collection: COLLECTIONS.USERS },
    { name: 'Stories', collection: COLLECTIONS.STORIES },
    { name: 'chats', collection: COLLECTIONS.CHATS },
    { name: 'Calls', collection: COLLECTIONS.CALLS },
    { name: 'reports', collection: COLLECTIONS.REPORTS },
    { name: 'admin_users', collection: COLLECTIONS.ADMIN_USERS },
    { name: 'admin_logs', collection: COLLECTIONS.ADMIN_LOGS },
  ];

  for (const col of collections) {
    try {
      const q = query(collection(db, col.collection), limit(1));
      const snapshot = await getDocs(q);

      if (snapshot.empty) {
        console.log(`⚠️  Collection "${col.name}": EXISTS but EMPTY (0 documents)`);
      } else {
        const fullSnapshot = await getDocs(collection(db, col.collection));
        console.log(`✅ Collection "${col.name}": ${fullSnapshot.size} documents`);

        // Show sample document structure
        const sampleDoc = snapshot.docs[0];
        console.log(`   Sample fields:`, Object.keys(sampleDoc.data()).join(', '));
      }
    } catch (error: any) {
      if (error.code === 'permission-denied') {
        console.log(`🔐 Collection "${col.name}": PERMISSION DENIED`);
        console.log(`   Your account needs read permission for this collection`);
      } else {
        console.log(`❌ Collection "${col.name}": ERROR - ${error.message}`);
      }
    }
  }

  console.log('\n📋 Diagnostics complete!');
}

/**
 * Check specific collection in detail
 */
export async function checkCollection(collectionName: string) {
  console.log(`\n🔍 Checking collection: ${collectionName}`);

  try {
    const snapshot = await getDocs(collection(db, collectionName));

    if (snapshot.empty) {
      console.log(`⚠️  Collection is EMPTY`);
      return { exists: true, empty: true, count: 0 };
    }

    console.log(`✅ Found ${snapshot.size} documents`);

    // Sample first document
    const sampleDoc = snapshot.docs[0].data();
    console.log('Sample document structure:', sampleDoc);

    return {
      exists: true,
      empty: false,
      count: snapshot.size,
      sampleFields: Object.keys(sampleDoc)
    };
  } catch (error: any) {
    console.error(`❌ Error:`, error.message);

    if (error.code === 'permission-denied') {
      return { exists: false, error: 'Permission denied', needsAuth: true };
    }

    return { exists: false, error: error.message };
  }
}

/**
 * Test Firebase connection
 */
export async function testFirebaseConnection() {
  console.log('🔥 Testing Firebase connection...');

  try {
    // Try to read from users collection (most likely to exist)
    const q = query(collection(db, COLLECTIONS.USERS), limit(1));
    await getDocs(q);
    console.log('✅ Firebase connection successful!');
    return true;
  } catch (error: any) {
    console.error('❌ Firebase connection failed:', error.message);
    return false;
  }
}
