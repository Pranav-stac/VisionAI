import firebase_admin
from firebase_admin import credentials, auth, db

# Initialize Firebase Admin SDK
cred = credentials.Certificate('firebase_admin_sdk.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://vision-ai-f6345-default-rtdb.firebaseio.com'
})

# Example function to verify a Firebase ID token
def verify_firebase_token(id_token):
    try:
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        return {'success': True, 'uid': uid}
    except Exception as e:
        return {'success': False, 'error': str(e)}

# Example route that requires authentication
@app.route('/protected-api', methods=['POST'])
def protected_api():
    # Get the token from request headers
    id_token = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    # Verify the token
    result = verify_firebase_token(id_token)
    
    if not result['success']:
        return jsonify({'error': 'Unauthorized'}), 401
    
    # Now you can use result['uid'] to identify the user
    # Access database, perform operations, etc.
    return jsonify({'message': 'Authenticated successfully'}) 