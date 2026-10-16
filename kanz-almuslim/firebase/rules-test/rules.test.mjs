import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, getDoc, deleteDoc, collection, query, where, getDocs, addDoc, runTransaction, serverTimestamp } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'kanz-rules-test',
  firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
});

const profile = (name, total = 0) => ({
  name, total, dayKey: '2026-10-15', dayCount: total, weekKey: '2026-10-10', weekCount: total,
  monthKey: '2026-10', monthCount: total, updatedAt: serverTimestamp(),
});

const alice = env.authenticatedContext('alice').firestore();
const bob = env.authenticatedContext('bob').firestore();
const carol = env.authenticatedContext('carol').firestore();
const anon = env.unauthenticatedContext().firestore();

describe('users', () => {
  beforeEach(async () => env.clearFirestore());

  it('creates own profile with zero points only', async () => {
    await assertSucceeds(setDoc(doc(alice, 'users/alice'), profile('Alice')));
    await assertFails(setDoc(doc(bob, 'users/alice2'), profile('X')));
    await assertFails(setDoc(doc(bob, 'users/bob'), profile('Bob', 500)));
  });

  it('points only go up, at most 2000 per write', async () => {
    await setDoc(doc(alice, 'users/alice'), profile('Alice'));
    await assertSucceeds(setDoc(doc(alice, 'users/alice'), profile('Alice', 1500), { merge: true }));
    await assertFails(setDoc(doc(alice, 'users/alice'), profile('Alice', 1000), { merge: true }));
    await assertFails(setDoc(doc(alice, 'users/alice'), profile('Alice', 5000), { merge: true }));
  });

  it('others cannot change my points; guests cannot read', async () => {
    await setDoc(doc(alice, 'users/alice'), profile('Alice'));
    await assertFails(updateDoc(doc(bob, 'users/alice'), { total: 10 }));
    await assertSucceeds(getDoc(doc(bob, 'users/alice')));
    await assertFails(getDoc(doc(anon, 'users/alice')));
  });

  it('assigns a friend code in one transaction', async () => {
    await setDoc(doc(alice, 'users/alice'), profile('Alice'));
    await assertSucceeds(runTransaction(alice, async (tx) => {
      tx.set(doc(alice, 'codes/ABC234'), { uid: 'alice' });
      tx.update(doc(alice, 'users/alice'), { code: 'ABC234' });
    }));
    // cannot claim a code that points to someone else
    await assertFails(setDoc(doc(bob, 'codes/ZZZ999'), { uid: 'alice' }));
  });
});

describe('friends and chat', () => {
  beforeEach(async () => {
    await env.clearFirestore();
    await setDoc(doc(alice, 'users/alice'), profile('Alice'));
    await setDoc(doc(bob, 'users/bob'), profile('Bob'));
  });

  it('request → accept → chat works only for the pair', async () => {
    await assertSucceeds(setDoc(doc(alice, 'friendRequests/alice_bob'), { from: 'alice', to: 'bob', fromName: 'Alice' }));
    // resending is allowed
    await assertSucceeds(setDoc(doc(alice, 'friendRequests/alice_bob'), { from: 'alice', to: 'bob', fromName: 'Alice' }));
    // bob sees it
    await assertSucceeds(getDocs(query(collection(bob, 'friendRequests'), where('to', '==', 'bob'))));
    // carol cannot read it
    await assertFails(getDoc(doc(carol, 'friendRequests/alice_bob')));

    // alice cannot accept her own request
    await assertFails(setDoc(doc(alice, 'friendships/alice_bob'), { members: ['bob', 'alice'], request: 'alice_bob' }));
    // bob accepts
    await assertSucceeds(setDoc(doc(bob, 'friendships/alice_bob'), { members: ['bob', 'alice'], request: 'alice_bob' }));
    await assertSucceeds(deleteDoc(doc(bob, 'friendRequests/alice_bob')));

    await assertSucceeds(getDocs(query(collection(alice, 'friendships'), where('members', 'array-contains', 'alice'))));

    await assertSucceeds(addDoc(collection(alice, 'friendships/alice_bob/messages'), { from: 'alice', text: 'السلام عليكم', at: serverTimestamp() }));
    await assertSucceeds(getDocs(collection(bob, 'friendships/alice_bob/messages')));
    await assertFails(getDocs(collection(carol, 'friendships/alice_bob/messages')));
    await assertFails(addDoc(collection(carol, 'friendships/alice_bob/messages'), { from: 'carol', text: 'hi', at: serverTimestamp() }));
    // cannot impersonate
    await assertFails(addDoc(collection(alice, 'friendships/alice_bob/messages'), { from: 'bob', text: 'x', at: serverTimestamp() }));
  });

  it('cannot create a friendship without a request', async () => {
    await assertFails(setDoc(doc(carol, 'friendships/alice_carol'), { members: ['carol', 'alice'], request: 'alice_carol' }));
  });

  it('competition request carries a verse message, at most 300 chars', async () => {
    const msg = '﴿وَفِي ذَٰلِكَ فَلْيَتَنَافَسِ الْمُتَنَافِسُونَ﴾ [المطففين: 26]';
    await assertSucceeds(setDoc(doc(alice, 'friendRequests/alice_carol'), { from: 'alice', to: 'carol', fromName: 'Alice', message: msg }));
    await assertSucceeds(getDoc(doc(carol, 'friendRequests/alice_carol')));
    await assertFails(setDoc(doc(alice, 'friendRequests/alice_carol'), { from: 'alice', to: 'carol', fromName: 'Alice', message: 'x'.repeat(301) }));
    await assertFails(setDoc(doc(alice, 'friendRequests/alice_carol'), { from: 'alice', to: 'carol', fromName: 'Alice', message: 42 }));
  });

  it('cannot forge a request from someone else', async () => {
    await assertFails(setDoc(doc(carol, 'friendRequests/alice_bob'), { from: 'alice', to: 'bob', fromName: 'A' }));
  });
});

after(async () => env.cleanup());
