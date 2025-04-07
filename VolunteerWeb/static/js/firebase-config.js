// Debug flag
const DEBUG = true;

function debugLog(message) {
    if (DEBUG) {
        console.log(`[Firebase Config] ${message}`);
    }
}

debugLog('Starting Firebase initialization...');

// Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyC3IDr4Hd2whhFsNOlhjuZ59kASXtEW-lQ",
    authDomain: "vision-ai-f6345.firebaseapp.com",
    databaseURL: "https://vision-ai-f6345-default-rtdb.firebaseio.com",
    projectId: "vision-ai-f6345",
    storageBucket: "vision-ai-f6345.appspot.com",
    messagingSenderId: "335489594965",
    appId: "1:335489594965:web:d1c8700db9dfedb74ec6dc",
    measurementId: "G-E3M7W3KFJV"
};

// Initialize Firebase with error handling
try {
    debugLog('Checking if Firebase SDK is loaded...');
    if (typeof firebase === 'undefined') {
        throw new Error('Firebase SDK is not loaded');
    }

    debugLog('Initializing Firebase...');
    if (!firebase.apps.length) {
        firebase.initializeApp(firebaseConfig);
        debugLog('Firebase initialized successfully!');
    }

    // Enable offline persistence for Realtime Database
    debugLog('Enabling offline persistence...');
    firebase.database().enablePersistence()
        .then(() => {
            debugLog('Offline persistence enabled');
        })
        .catch((err) => {
            if (err.code === 'failed-precondition') {
                console.warn('Multiple tabs open, persistence can only be enabled in one tab at a time.');
            } else if (err.code === 'unimplemented') {
                console.warn('The current browser does not support persistence');
            }
        });

    // Initialize services
    debugLog('Initializing Firebase services...');
    const auth = firebase.auth();
    const db = firebase.database();
    const storage = firebase.storage();

    // Make services globally available
    window.auth = auth;
    window.db = db;
    window.storage = storage;

    // Add real-time connection state listener
    const connectedRef = db.ref('.info/connected');
    connectedRef.on('value', (snap) => {
        if (snap.val() === true) {
            debugLog('Connected to Firebase Real-time Database');
        } else {
            debugLog('Disconnected from Firebase Real-time Database');
        }
    });

    debugLog('Firebase services initialization complete');

} catch (error) {
    console.error('[Firebase Config] Error:', error);
    debugLog('Firebase initialization failed: ' + error.message);
}