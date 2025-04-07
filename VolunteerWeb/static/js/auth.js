// Add at the beginning of the file
function checkFirebaseStatus() {
    console.log('[Auth] Checking Firebase status...');
    
    // Check if Firebase SDK is loaded
    if (typeof firebase === 'undefined') {
        console.error('[Auth] Firebase SDK not loaded');
        return false;
    }
    
    // Check if Firebase is initialized
    if (!firebase.apps.length) {
        console.error('[Auth] Firebase not initialized');
        return false;
    }
    
    // Check if services are available
    try {
        const auth = firebase.auth();
        const db = firebase.database();
        const storage = firebase.storage();
        
        if (!auth || !db || !storage) {
            throw new Error('Firebase services not available');
        }
        
        console.log('[Auth] Firebase is ready');
        return true;
    } catch (error) {
        console.error('[Auth] Firebase services error:', error);
        return false;
    }
}

// Add these functions at the top of the file
function updateUIForAuthenticatedUser(user) {
    console.log('[Auth] Updating UI for authenticated user:', user.email);
    // Add any UI updates for authenticated state
    const loginBtn = document.querySelector('.nav-item a[href="/login"]');
    const registerBtn = document.querySelector('.nav-item a[href="/register"]');
    const dashboardBtn = document.querySelector('.nav-item a[href="/dashboard"]');
    const logoutBtn = document.querySelector('.nav-item a[href="/logout"]');

    if (loginBtn) loginBtn.style.display = 'none';
    if (registerBtn) registerBtn.style.display = 'none';
    if (dashboardBtn) dashboardBtn.style.display = 'block';
    if (logoutBtn) logoutBtn.style.display = 'block';
}

function updateUIForAnonymousUser() {
    console.log('[Auth] Updating UI for anonymous user');
    // Add any UI updates for non-authenticated state
    const loginBtn = document.querySelector('.nav-item a[href="/login"]');
    const registerBtn = document.querySelector('.nav-item a[href="/register"]');
    const dashboardBtn = document.querySelector('.nav-item a[href="/dashboard"]');
    const logoutBtn = document.querySelector('.nav-item a[href="/logout"]');

    if (loginBtn) loginBtn.style.display = 'block';
    if (registerBtn) registerBtn.style.display = 'block';
    if (dashboardBtn) dashboardBtn.style.display = 'none';
    if (logoutBtn) logoutBtn.style.display = 'none';
}

// Add initialization check at the start of DOMContentLoaded
document.addEventListener('DOMContentLoaded', async function() {
    console.log('[Auth] DOM Content Loaded');
    
    // Wait for Firebase to initialize
    let retries = 0;
    const maxRetries = 5;
    
    while (!checkFirebaseStatus() && retries < maxRetries) {
        console.log('[Auth] Waiting for Firebase initialization...');
        await new Promise(resolve => setTimeout(resolve, 1000));
        retries++;
    }
    
    if (!checkFirebaseStatus()) {
        console.error('[Auth] Firebase failed to initialize after', maxRetries, 'attempts');
        return;
    }

    // Registration form handling
    const registrationForm = document.getElementById('registrationForm');
    if (registrationForm) {
        registrationForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            console.log('[Auth] Registration form submitted');
            
            if (!this.checkValidity()) {
                console.log('[Auth] Form validation failed');
                this.classList.add('was-validated');
                return;
            }

            try {
                const email = this.email.value.trim();
                const password = this.password.value;
                const fullName = this.fullName.value.trim();
                
                if (!email || !password || !fullName) {
                    throw new Error('All fields are required');
                }

                console.log('[Auth] Creating user account...');
                
                // First check if Firebase Auth is properly initialized
                if (!firebase.auth()) {
                    throw new Error('Firebase Auth is not initialized');
                }

                // Create user with error handling
                const userCredential = await firebase.auth().createUserWithEmailAndPassword(email, password)
                    .catch(error => {
                        console.error('[Auth] Firebase createUser error:', error);
                        throw error;
                    });

                const user = userCredential.user;
                console.log('[Auth] User created successfully:', user.uid);

                // Update profile
                await user.updateProfile({
                    displayName: fullName
                });
                
                // Add user data to Realtime Database
                await firebase.database().ref('users/' + user.uid).set({
                    fullName: fullName,
                    email: email,
                    type: 'individual',
                    createdAt: new Date().toISOString(),
                    verified: false
                });
                
                console.log('[Auth] User data stored in database');
                
                // Send email verification
                await user.sendEmailVerification();
                console.log('[Auth] Verification email sent');

                alert('Registration successful! Please check your email for verification.');
                window.location.href = '/login';
                
            } catch (error) {
                console.error('[Auth] Registration error:', error);
                let errorMessage = 'Registration failed. ';
                
                switch (error.code) {
                    case 'auth/email-already-in-use':
                        errorMessage += 'This email is already registered.';
                        break;
                    case 'auth/invalid-email':
                        errorMessage += 'Please enter a valid email address.';
                        break;
                    case 'auth/operation-not-allowed':
                        errorMessage += 'Email/password accounts are not enabled. Please contact support.';
                        break;
                    case 'auth/weak-password':
                        errorMessage += 'Please choose a stronger password (at least 6 characters).';
                        break;
                    default:
                        errorMessage += error.message || 'Please try again later.';
                }
                
                alert(errorMessage);
            }
        });
    }

    // Login form handling
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const email = this.email.value;
            const password = this.password.value;
            
            try {
                const userCredential = await firebase.auth().signInWithEmailAndPassword(email, password);
                const user = userCredential.user;
                
                // Update last login timestamp
                await firebase.database().ref(`users/${user.uid}`).update({
                    lastLogin: firebase.database.ServerValue.TIMESTAMP
                });
                
                // Get user data and redirect
                const userRef = firebase.database().ref(`users/${user.uid}`);
                userRef.once('value', (snapshot) => {
                    const userData = snapshot.val();
                    if (userData) {
                        // Redirect based on user type
                        window.location.href = userData.type === 'individual' ? '/volunteer-dashboard' : '/org-dashboard';
                    } else {
                        // Check organizations if user not found in users
                        firebase.database().ref(`organizations/${user.uid}`).once('value', (orgSnapshot) => {
                            if (orgSnapshot.exists()) {
                                window.location.href = '/org-dashboard';
                            } else {
                                console.error('User data not found');
                                alert('User profile not found');
                            }
                        });
                    }
                });
                
            } catch (error) {
                console.error('Login error:', error);
                alert(error.message);
            }
        });
    }
});

// Social login handlers
const googleLogin = async () => {
    const provider = new firebase.auth.GoogleAuthProvider();
    try {
        const result = await firebase.auth().signInWithPopup(provider);
        const user = result.user;
        
        // Check if user exists in database
        const userRef = firebase.database().ref('users/' + user.uid);
        const snapshot = await userRef.once('value');
        
        if (!snapshot.exists()) {
            // Create new user document
            await userRef.set({
                fullName: user.displayName,
                email: user.email,
                type: 'individual',
                createdAt: new Date().toISOString(),
                verified: true
            });
            window.location.href = '/volunteer-dashboard';
        } else {
            // Redirect based on existing user type
            const userData = snapshot.val();
            window.location.href = userData.type === 'individual' ? '/volunteer-dashboard' : '/org-dashboard';
        }
    } catch (error) {
        console.error('Google login error:', error);
        alert(error.message);
    }
};

// Add real-time user presence system
function initializePresence(uid) {
    const userStatusRef = firebase.database().ref(`/status/${uid}`);
    const userRef = firebase.database().ref(`/users/${uid}`);

    // Create a reference to the special '.info/connected' path in Firebase Realtime Database
    const connectedRef = firebase.database().ref('.info/connected');

    connectedRef.on('value', (snap) => {
        if (snap.val() === true) {
            // We're connected (or reconnected)!
            const presence = {
                status: 'online',
                last_seen: firebase.database.ServerValue.TIMESTAMP
            };

            // Set the /status/<uid> value to 'online'
            userStatusRef.onDisconnect()
                .set({
                    status: 'offline',
                    last_seen: firebase.database.ServerValue.TIMESTAMP
                })
                .then(() => {
                    userStatusRef.set(presence);
                });

            // Update user's online status
            userRef.update({
                online: true,
                last_seen: firebase.database.ServerValue.TIMESTAMP
            });
        }
    });
}

// Update the auth state observer
firebase.auth().onAuthStateChanged((user) => {
    if (user) {
        // User is signed in
        initializePresence(user.uid);
        
        // Set up real-time listener for user data
        const userRef = firebase.database().ref(`users/${user.uid}`);
        userRef.on('value', (snapshot) => {
            const userData = snapshot.val();
            if (userData) {
                updateUIForAuthenticatedUser(userData);
            }
        });
    } else {
        // User is signed out
        updateUIForAnonymousUser();
    }
}); 