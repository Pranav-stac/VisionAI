from flask import Flask, render_template, request, redirect, url_for, flash, session, jsonify
import firebase_admin
from firebase_admin import credentials, auth as admin_auth, db
import pyrebase
import os
import json
from werkzeug.utils import secure_filename
from datetime import datetime
import uuid
import logging
import pytz
from dateutil.parser import parse
from dateutil import tz

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = 'vision_ai_volunteer_portal_secret_key'

# Update the Firebase Admin SDK initialization
cred = credentials.Certificate("vision-ai-f6345-firebase-adminsdk-fbsvc-c2e0563bf0.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://vision-ai-f6345-default-rtdb.firebaseio.com',
    'projectId': 'vision-ai-f6345',
    'storageBucket': 'vision-ai-f6345.appspot.com',
    'authDomain': 'vision-ai-f6345.firebaseapp.com'
})

# Update the Firebase client configuration
firebase_config = {
    "apiKey": "AIzaSyC3IDr4Hd2whhFsNOlhjuZ59kASXtEW-lQ",
    "authDomain": "vision-ai-f6345.firebaseapp.com",
    "databaseURL": "https://vision-ai-f6345-default-rtdb.firebaseio.com",
    "projectId": "vision-ai-f6345",
    "storageBucket": "vision-ai-f6345.appspot.com",
    "messagingSenderId": "335489594965",
    "appId": "1:335489594965:web:d1c8700db9dfedb74ec6dc",
    "measurementId": "G-E3M7W3KFJV"
}

# Update Pyrebase initialization
try:
    logger.debug("Initializing Pyrebase...")
    firebase = pyrebase.initialize_app(firebase_config)
    auth = firebase.auth()
    pyrebase_db = firebase.database()
    storage = firebase.storage()
    logger.info("Pyrebase initialized successfully!")
except Exception as e:
    logger.error(f"Pyrebase initialization error: {str(e)}")
    raise

# Add this near the top of your file, after creating the Flask app
def time_ago(dt_str):
    """Convert a datetime string to a "time ago" string"""
    try:
        # Parse the datetime string
        if isinstance(dt_str, str):
            dt = parse(dt_str)
        else:
            dt = dt_str
            
        # Make sure datetime is timezone-aware
        if dt.tzinfo is None:
            dt = pytz.UTC.localize(dt)
            
        now = datetime.now(pytz.UTC)
        diff = now - dt

        seconds = diff.total_seconds()
        if seconds < 60:
            return 'just now'
        elif seconds < 3600:
            minutes = int(seconds / 60)
            return f'{minutes} minute{"s" if minutes != 1 else ""} ago'
        elif seconds < 86400:
            hours = int(seconds / 3600)
            return f'{hours} hour{"s" if hours != 1 else ""} ago'
        elif seconds < 604800:
            days = int(seconds / 86400)
            return f'{days} day{"s" if days != 1 else ""} ago'
        elif seconds < 2592000:
            weeks = int(seconds / 604800)
            return f'{weeks} week{"s" if weeks != 1 else ""} ago'
        elif seconds < 31536000:
            months = int(seconds / 2592000)
            return f'{months} month{"s" if months != 1 else ""} ago'
        else:
            years = int(seconds / 31536000)
            return f'{years} year{"s" if years != 1 else ""} ago'
    except Exception:
        return str(dt_str)

# Register the filter with Jinja2
app.jinja_env.filters['time_ago'] = time_ago

# Add these custom filters after creating the Flask app
def format_date(dt_str):
    """Convert a datetime string to a formatted date"""
    try:
        if isinstance(dt_str, str):
            dt = parse(dt_str)
        else:
            dt = dt_str
        return dt.strftime('%B %d, %Y')
    except Exception:
        return str(dt_str)

# Register all custom filters
app.jinja_env.filters['date'] = format_date

# Add this after creating the Flask app
@app.template_filter('dateformat')
def dateformat_filter(date, format='%d'):
    """Convert a date to a different format."""
    if isinstance(date, str):
        try:
            date = datetime.fromisoformat(date.replace('Z', '+00:00'))
        except ValueError:
            return date
    
    if isinstance(date, datetime):
        return date.strftime(format)
    return date

# Add this after creating the Flask app
@app.template_filter('datetime')
def parse_datetime(date_str):
    """Convert a date string to a datetime object."""
    try:
        return datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except (ValueError, AttributeError):
        return None

# Routes
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/dashboard')
def dashboard():
    if 'user' not in session:
        flash('Please login first', 'warning')
        return redirect(url_for('login'))
    
    user_id = session['user']['localId']
    user_type = session['user'].get('type')
    
    if user_type == 'organization':
        return redirect(url_for('org_dashboard'))
    else:
        return redirect(url_for('volunteer_dashboard'))

@app.route('/volunteer-dashboard')
def volunteer_dashboard():
    if 'user' not in session:
        flash('Please login first', 'warning')
        return redirect(url_for('login'))
    
    user_id = session['user']['localId']
    
    # Get volunteer data
    volunteer_data = pyrebase_db.child("users").child(user_id).get().val()
    if not volunteer_data:
        flash('User profile not found', 'danger')
        return redirect(url_for('logout'))
    
    # Get help requests
    requests = pyrebase_db.child("help_requests").get().val() or {}
    
    # Count urgent requests
    urgent_count = 0
    if requests:
        for request_id, request_data in requests.items():
            if request_data.get('priority') == 'urgent':
                urgent_count += 1
    
    return render_template('volunteer_dashboard.html', volunteer=volunteer_data, requests=requests, urgent_count=urgent_count)

@app.route('/org-dashboard')
def org_dashboard():
    if 'user' not in session:
        flash('Please login first', 'warning')
        return redirect(url_for('login'))
    
    user_id = session['user']['localId']
    
    # Get organization data
    org_data = pyrebase_db.child("organizations").child(user_id).get().val()
    if not org_data:
        flash('Organization profile not found', 'danger')
        return redirect(url_for('logout'))
    
    # Get help requests
    requests = pyrebase_db.child("help_requests").get().val() or {}
    
    return render_template('org_dashboard.html', org=org_data, requests=requests)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        try:
            email = request.form.get('email')
            password = request.form.get('password')
            
            # Authenticate user
            user = auth.sign_in_with_email_and_password(email, password)
            
            # Get user data
            user_data = pyrebase_db.child("users").child(user['localId']).get()
            
            if user_data.val():
                session['user'] = user_data.val()
                session['user']['localId'] = user['localId']  # Add user ID to session
                flash('Login successful!', 'success')
                
                # Redirect based on user type
                if user_data.val().get('type') == 'individual':
                    return redirect(url_for('volunteer_dashboard'))
                else:
                    return redirect(url_for('org_dashboard'))
            
        except Exception as e:
            flash(f'Login failed: {str(e)}', 'danger')
            logger.error(f"Login error: {str(e)}")
            
    return render_template('login.html')

@app.route('/register')
def register():
    return render_template('register.html')

@app.route('/register/individual', methods=['GET', 'POST'])
def register_individual():
    if request.method == 'POST':
        try:
            logger.debug("Processing individual registration...")
            email = request.form.get('email')
            password = request.form.get('password')
            full_name = request.form.get('fullName')
            
            if not all([email, password, full_name]):
                raise ValueError("All fields are required")
            
            # Create user with Firebase Admin SDK
            logger.debug(f"Creating user with email: {email}")
            user = admin_auth.create_user(
                email=email,
                password=password,
                display_name=full_name,
                email_verified=False
            )
            logger.info(f"User created successfully with ID: {user.uid}")
            
            # Store additional user data in Realtime Database
            user_data = {
                'fullName': full_name,
                'email': email,
                'type': 'individual',
                'verified': False,
                'createdAt': datetime.now().isoformat()
            }
            
            db.reference(f'users/{user.uid}').set(user_data)
            logger.info("User data stored in database")
            
            # Send verification email using Pyrebase
            user_credentials = auth.sign_in_with_email_and_password(email, password)
            auth.send_email_verification(user_credentials['idToken'])
            logger.info("Verification email sent")
            
            flash('Registration successful! Please verify your email.', 'success')
            return redirect(url_for('login'))
            
        except Exception as e:
            logger.error(f"Registration error: {str(e)}")
            error_message = str(e)
            if 'INVALID_EMAIL' in error_message:
                flash('Invalid email address', 'danger')
            elif 'WEAK_PASSWORD' in error_message:
                flash('Password should be at least 6 characters', 'danger')
            elif 'EMAIL_EXISTS' in error_message:
                flash('Email already exists', 'danger')
            else:
                flash(f'Registration failed: {error_message}', 'danger')
            return redirect(url_for('register_individual'))
            
    return render_template('register_individual.html')

@app.route('/register/organization', methods=['GET', 'POST'])
def register_organization():
    if request.method == 'POST':
        org_name = request.form['org_name']
        email = request.form['email']
        password = request.form['password']
        phone = request.form['phone']
        website = request.form['website']
        reg_number = request.form['reg_number']
        
        # Handle registration document upload
        reg_document = request.files['reg_document']
        if reg_document:
            filename = secure_filename(reg_document.filename)
            unique_filename = f"{uuid.uuid4()}_{filename}"
            reg_document.save(os.path.join("instance", unique_filename))
            
            # Upload to Firebase Storage
            storage.child(f"org_documents/{unique_filename}").put(os.path.join("instance", unique_filename))
            reg_document_url = storage.child(f"org_documents/{unique_filename}").get_url(None)
            
            # Remove local file after upload
            os.remove(os.path.join("instance", unique_filename))
        
        try:
            # Create user in Firebase Auth
            user = auth.create_user_with_email_and_password(email, password)
            
            # Store additional information in Realtime Database
            org_data = {
                "org_name": org_name,
                "email": email,
                "phone": phone,
                "website": website,
                "reg_number": reg_number,
                "reg_document_url": reg_document_url if reg_document else "",
                "type": "organization",
                "verification_status": "pending",
                "created_at": datetime.now().isoformat(),
                "domains": []
            }
            
            pyrebase_db.child("organizations").child(user['localId']).set(org_data)
            
            flash('Organization registration successful! Please wait for verification.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            flash('Registration failed: ' + str(e), 'danger')
            
    return render_template('register_organization.html')

@app.route('/request/<request_id>')
def view_request(request_id):
    if 'user' not in session:
        flash('Please login first', 'warning')
        return redirect(url_for('login'))
    
    help_request = pyrebase_db.child("help_requests").child(request_id).get().val()
    if not help_request:
        flash('Request not found', 'warning')
        return redirect(url_for('dashboard'))
    
    # Get requester info
    requester = pyrebase_db.child("users").child(help_request.get('user_id')).get().val() or {}
    
    return render_template('request_details.html', request=help_request, request_id=request_id, requester=requester)

@app.route('/accept-request/<request_id>', methods=['POST'])
def accept_request(request_id):
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    user_id = session['user']['localId']
    
    try:
        # Get the request data first
        request_data = pyrebase_db.child("help_requests").child(request_id).get().val()
        
        if not request_data:
            return jsonify({'success': False, 'message': 'Request not found'}), 404
        
        if request_data.get('status') == 'accepted':
            return jsonify({'success': False, 'message': 'Request already accepted'}), 400
        
        # Add volunteer information and status
        request_data.update({
            "status": "assigned",
            "volunteer_id": user_id,
            "accepted_at": datetime.now(pytz.UTC).isoformat()
        })
        
        # Move to assigned_requests collection
        pyrebase_db.child("assigned_requests").child(request_id).set(request_data)
        
        # Remove from help_requests
        pyrebase_db.child("help_requests").child(request_id).remove()
        
        # Update volunteer stats
        volunteer_ref = pyrebase_db.child("users").child(user_id)
        volunteer_data = volunteer_ref.get().val() or {}
        
        # Increment assignment count
        current_count = volunteer_data.get('assignments_count', 0)
        volunteer_ref.update({
            "assignments_count": current_count + 1,
            "last_assignment": datetime.now(pytz.UTC).isoformat()
        })
        
        # Add to volunteer's active assignments
        active_assignments = volunteer_data.get('active_assignments', {})
        active_assignments[request_id] = {
            "request_id": request_id,
            "title": request_data.get('title'),
            "accepted_at": datetime.now(pytz.UTC).isoformat()
        }
        volunteer_ref.child('active_assignments').set(active_assignments)
        
        return jsonify({
            'success': True,
            'message': 'Request accepted successfully!'
        })
        
    except Exception as e:
        logger.error(f"Error accepting request: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/complete-request/<request_id>', methods=['POST'])
def complete_request(request_id):
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    user_id = session['user']['localId']
    
    try:
        # Get the assigned request data
        request_data = pyrebase_db.child("assigned_requests").child(request_id).get().val()
        
        if not request_data:
            return jsonify({'success': False, 'message': 'Request not found'}), 404
        
        # Verify this volunteer is assigned to this request
        if request_data.get('volunteer_id') != user_id:
            return jsonify({'success': False, 'message': 'You are not assigned to this request'}), 403
        
        # Update status and completion data
        request_data.update({
            "status": "completed",
            "completed_at": datetime.now(pytz.UTC).isoformat()
        })
        
        # Move to completed_requests collection
        pyrebase_db.child("completed_requests").child(request_id).set(request_data)
        
        # Remove from assigned_requests
        pyrebase_db.child("assigned_requests").child(request_id).remove()
        
        # Update volunteer stats
        volunteer_ref = pyrebase_db.child("users").child(user_id)
        volunteer_data = volunteer_ref.get().val() or {}
        
        # Increment completion count
        current_count = volunteer_data.get('completions_count', 0)
        volunteer_ref.update({
            "completions_count": current_count + 1,
            "last_completion": datetime.now(pytz.UTC).isoformat()
        })
        
        # Remove from active assignments
        active_assignments = volunteer_data.get('active_assignments', {})
        if request_id in active_assignments:
            del active_assignments[request_id]
            volunteer_ref.child('active_assignments').set(active_assignments)
        
        # Add to completed assignments
        completed_assignments = volunteer_data.get('completed_assignments', {})
        completed_assignments[request_id] = {
            "request_id": request_id,
            "title": request_data.get('title'),
            "completed_at": datetime.now(pytz.UTC).isoformat()
        }
        volunteer_ref.child('completed_assignments').set(completed_assignments)
        
        return jsonify({
            'success': True,
            'message': 'Request marked as completed!'
        })
        
    except Exception as e:
        logger.error(f"Error completing request: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

# New routes for skills and events management
@app.route('/add-skill', methods=['POST'])
def add_skill():
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    user_id = session['user']['localId']
    
    try:
        skill_data = request.json
        skill = skill_data.get('skill')
        
        if not skill:
            return jsonify({'success': False, 'message': 'Skill cannot be empty'}), 400
        
        # Get current skills
        user_ref = pyrebase_db.child("users").child(user_id)
        user_data = user_ref.get().val() or {}
        current_skills = user_data.get('skills', [])
        
        if skill not in current_skills:
            current_skills.append(skill)
            user_ref.update({"skills": current_skills})
        
        return jsonify({'success': True, 'message': 'Skill added successfully!'})
        
    except Exception as e:
        logger.error(f"Error adding skill: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/add-event', methods=['POST'])
def add_event():
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    user_id = session['user']['localId']
    
    try:
        event_data = request.json
        title = event_data.get('title')
        date = event_data.get('date')
        time = event_data.get('time')
        
        if not all([title, date, time]):
            return jsonify({'success': False, 'message': 'All fields are required'}), 400
        
        # Create event object
        event = {
            "title": title,
            "date": date,
            "time": time,
            "created_at": datetime.now(pytz.UTC).isoformat()
        }
        
        # Get current schedule
        user_ref = pyrebase_db.child("users").child(user_id)
        user_data = user_ref.get().val() or {}
        schedule = user_data.get('schedule', {})
        
        # Generate unique ID for the event
        event_id = str(uuid.uuid4())
        schedule[event_id] = event
        
        # Update user's schedule
        user_ref.child('schedule').set(schedule)
        
        return jsonify({'success': True, 'message': 'Event added successfully!'})
        
    except Exception as e:
        logger.error(f"Error adding event: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/logout')
def logout():
    session.pop('user', None)
    flash('You have been logged out.', 'success')
    return redirect(url_for('index'))

@app.route('/profile/<user_type>/<user_id>')
def profile(user_type, user_id):
    if 'user' not in session:
        flash('Please login first', 'warning')
        return redirect(url_for('login'))
    
    current_user_id = session['user']['localId']
    
    # Only allow access to own profile
    if current_user_id != user_id:
        flash('You do not have permission to view this profile', 'danger')
        return redirect(url_for('dashboard'))
    
    if user_type == 'volunteer':
        volunteer_data = pyrebase_db.child("users").child(user_id).get().val()
        if volunteer_data:
            # Add localId to the volunteer data so it's accessible in the template
            volunteer_data['localId'] = user_id
            return render_template('volunteer_profile.html', volunteer=volunteer_data)
    elif user_type == 'organization':
        org_data = pyrebase_db.child("organizations").child(user_id).get().val()
        if org_data:
            # Add localId to the org data so it's accessible in the template
            org_data['localId'] = user_id
            return render_template('org_profile.html', org=org_data)
    
    flash('Profile not found', 'danger')
    return redirect(url_for('dashboard'))

@app.route('/test-firebase')
def test_firebase():
    try:
        logger.debug("Testing Firebase connection...")
        # Try to read from the database
        test_ref = pyrebase_db.child("test").get()
        logger.info("Firebase connection successful!")
        return jsonify({
            "status": "success",
            "message": "Firebase connection successful",
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Firebase test failed: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/test-firebase-auth')
def test_firebase_auth():
    try:
        # Test user creation (will not actually create)
        auth.get_account_info("test")
        return jsonify({
            "status": "success",
            "message": "Firebase Auth is properly configured",
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Firebase Auth test failed: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/test-firebase-config')
def test_firebase_config():
    try:
        # Test Admin SDK
        logger.debug("Testing Admin SDK...")
        admin_test = admin_auth.list_users(max_results=1)
        logger.info("Admin SDK test successful")

        # Test Pyrebase Database
        logger.debug("Testing Pyrebase Database...")
        test_ref = pyrebase_db.child('test').set({"timestamp": datetime.now().isoformat()})
        logger.info("Pyrebase Database test successful")

        # Test Pyrebase Auth
        logger.debug("Testing Pyrebase Auth...")
        try:
            # Try to get a test user (this will fail safely if user doesn't exist)
            test_user = auth.get_account_info("test_token")
        except Exception as auth_error:
            logger.warning(f"Auth test expected error: {str(auth_error)}")

        return jsonify({
            "status": "success",
            "message": "Firebase configuration is working correctly",
            "admin_sdk": "Connected",
            "pyrebase": "Connected",
            "database": "Connected",
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Firebase configuration test failed: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/create-request', methods=['POST'])
def create_request():
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    user_id = session['user']['localId']
    
    try:
        # Get request data from form
        request_data = request.json
        
        # Validate required fields
        if not all([
            request_data.get('title'),
            request_data.get('description'),
            request_data.get('location')
        ]):
            return jsonify({'success': False, 'message': 'All required fields must be filled out'}), 400
        
        # Create request object
        new_request = {
            "title": request_data.get('title'),
            "description": request_data.get('description'),
            "location": request_data.get('location'),
            "priority": request_data.get('priority', 'low'),
            "request_type": request_data.get('request_type', 'other'),
            "skills": request_data.get('skills', []),
            "status": "active",
            "org_id": user_id,
            "created_at": datetime.now(pytz.UTC).isoformat()
        }
        
        # Generate a unique ID for the request
        request_id = pyrebase_db.child("help_requests").push(new_request)['name']
        
        return jsonify({
            'success': True,
            'message': 'Help request created successfully!',
            'request_id': request_id
        })
        
    except Exception as e:
        logger.error(f"Error creating request: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/add-domain', methods=['POST'])
def add_domain():
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    user_id = session['user']['localId']
    
    try:
        domain_data = request.json
        domain = domain_data.get('domain')
        
        if not domain:
            return jsonify({'success': False, 'message': 'Domain name cannot be empty'}), 400
        
        # Get current domains
        org_ref = pyrebase_db.child("organizations").child(user_id)
        org_data = org_ref.get().val() or {}
        current_domains = org_data.get('domains', [])
        
        if domain not in current_domains:
            current_domains.append(domain)
            org_ref.update({"domains": current_domains})
        
        return jsonify({'success': True, 'message': 'Service domain added successfully!'})
        
    except Exception as e:
        logger.error(f"Error adding domain: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/add-volunteer', methods=['POST'])
def add_volunteer():
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    org_id = session['user']['localId']
    
    try:
        volunteer_data = request.json
        email = volunteer_data.get('email')
        role = volunteer_data.get('role', 'volunteer')
        notes = volunteer_data.get('notes', '')
        
        if not email:
            return jsonify({'success': False, 'message': 'Volunteer email cannot be empty'}), 400
        
        # Look up user by email
        try:
            user = admin_auth.get_user_by_email(email)
            volunteer_id = user.uid
        except Exception as e:
            return jsonify({'success': False, 'message': f'Volunteer not found: {str(e)}'}), 404
        
        # Check if user exists in the 'users' collection
        volunteer = pyrebase_db.child("users").child(volunteer_id).get().val()
        if not volunteer:
            return jsonify({'success': False, 'message': 'User is not registered as a volunteer'}), 404
        
        # Add volunteer to organization's volunteer list
        org_ref = pyrebase_db.child("organizations").child(org_id)
        org_data = org_ref.get().val() or {}
        volunteers = org_data.get('volunteers', {})
        
        volunteers[volunteer_id] = {
            "name": volunteer.get('fullName', 'Volunteer'),
            "email": email,
            "role": role,
            "notes": notes,
            "added_at": datetime.now(pytz.UTC).isoformat(),
            "status": "active"
        }
        
        org_ref.child('volunteers').set(volunteers)
        
        # Also add organization to volunteer's organization list
        volunteer_orgs = volunteer.get('organizations', {})
        volunteer_orgs[org_id] = {
            "org_name": org_data.get('org_name', 'Organization'),
            "role": role,
            "joined_at": datetime.now(pytz.UTC).isoformat()
        }
        
        pyrebase_db.child("users").child(volunteer_id).child('organizations').set(volunteer_orgs)
        
        return jsonify({'success': True, 'message': 'Volunteer added successfully!'})
        
    except Exception as e:
        logger.error(f"Error adding volunteer: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/assign-request', methods=['POST'])
def assign_request():
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    org_id = session['user']['localId']
    
    try:
        assignment_data = request.json
        request_id = assignment_data.get('request_id')
        volunteer_id = assignment_data.get('volunteer_id')
        notes = assignment_data.get('notes', '')
        
        if not request_id or not volunteer_id:
            return jsonify({'success': False, 'message': 'Request ID and volunteer ID are required'}), 400
        
        # Get request data
        request_data = pyrebase_db.child("help_requests").child(request_id).get().val()
        if not request_data:
            return jsonify({'success': False, 'message': 'Request not found'}), 404
        
        # Verify the organization owns this request
        if request_data.get('org_id') != org_id:
            return jsonify({'success': False, 'message': 'You do not have permission to assign this request'}), 403
        
        # Get volunteer data
        volunteer_data = pyrebase_db.child("users").child(volunteer_id).get().val()
        if not volunteer_data:
            return jsonify({'success': False, 'message': 'Volunteer not found'}), 404
        
        # Update request with volunteer information and assignment details
        request_data.update({
            "status": "assigned",
            "volunteer_id": volunteer_id,
            "volunteer_name": volunteer_data.get('fullName', 'Volunteer'),
            "assignment_notes": notes,
            "assigned_at": datetime.now(pytz.UTC).isoformat()
        })
        
        # Move to assigned_requests collection in organization
        org_ref = pyrebase_db.child("organizations").child(org_id)
        assigned_requests = org_ref.child("assigned_requests").get().val() or {}
        assigned_requests[request_id] = request_data
        org_ref.child("assigned_requests").set(assigned_requests)
        
        # Remove from help_requests
        pyrebase_db.child("help_requests").child(request_id).remove()
        
        # Add to volunteer's active assignments
        volunteer_ref = pyrebase_db.child("users").child(volunteer_id)
        active_assignments = volunteer_ref.child("active_assignments").get().val() or {}
        active_assignments[request_id] = {
            "request_id": request_id,
            "title": request_data.get('title'),
            "assigned_at": datetime.now(pytz.UTC).isoformat(),
            "org_id": org_id,
            "org_name": session['user'].get('org_name', 'Organization')
        }
        volunteer_ref.child('active_assignments').set(active_assignments)
        
        # Update assignment count for the volunteer
        assignments_count = volunteer_data.get('assignments_count', 0)
        volunteer_ref.update({
            "assignments_count": assignments_count + 1,
            "last_assignment": datetime.now(pytz.UTC).isoformat()
        })
        
        return jsonify({
            'success': True,
            'message': 'Request assigned successfully!'
        })
        
    except Exception as e:
        logger.error(f"Error assigning request: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/archive-request/<request_id>', methods=['POST'])
def archive_request(request_id):
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    org_id = session['user']['localId']
    
    try:
        # Get the completed request data
        org_ref = pyrebase_db.child("organizations").child(org_id)
        completed_requests = org_ref.child("completed_requests").get().val() or {}
        
        request_data = completed_requests.get(request_id)
        if not request_data:
            return jsonify({'success': False, 'message': 'Completed request not found'}), 404
        
        # Move to archived_requests collection
        archived_requests = org_ref.child("archived_requests").get().val() or {}
        request_data["archived_at"] = datetime.now(pytz.UTC).isoformat()
        archived_requests[request_id] = request_data
        
        org_ref.child("archived_requests").set(archived_requests)
        
        # Remove from completed_requests
        completed_requests.pop(request_id)
        org_ref.child("completed_requests").set(completed_requests)
        
        return jsonify({
            'success': True,
            'message': 'Request archived successfully!'
        })
        
    except Exception as e:
        logger.error(f"Error archiving request: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/org/complete-request/<request_id>', methods=['POST'])
def org_complete_request(request_id):
    if 'user' not in session:
        return jsonify({'success': False, 'message': 'Please login first'}), 401
    
    org_id = session['user']['localId']
    
    try:
        # Get the assigned request data
        org_ref = pyrebase_db.child("organizations").child(org_id)
        assigned_requests = org_ref.child("assigned_requests").get().val() or {}
        
        request_data = assigned_requests.get(request_id)
        if not request_data:
            return jsonify({'success': False, 'message': 'Assigned request not found'}), 404
        
        # Update status and completion data
        request_data.update({
            "status": "completed",
            "completed_at": datetime.now(pytz.UTC).isoformat(),
            "completed_by_org": True
        })
        
        # Move to completed_requests collection
        completed_requests = org_ref.child("completed_requests").get().val() or {}
        completed_requests[request_id] = request_data
        org_ref.child("completed_requests").set(completed_requests)
        
        # Remove from assigned_requests
        assigned_requests.pop(request_id)
        org_ref.child("assigned_requests").set(assigned_requests)
        
        # Update volunteer stats if there's a volunteer assigned
        volunteer_id = request_data.get('volunteer_id')
        if volunteer_id:
            volunteer_ref = pyrebase_db.child("users").child(volunteer_id)
            volunteer_data = volunteer_ref.get().val() or {}
            
            # Increment completion count
            completions_count = volunteer_data.get('completions_count', 0)
            volunteer_ref.update({
                "completions_count": completions_count + 1,
                "last_completion": datetime.now(pytz.UTC).isoformat()
            })
            
            # Remove from active assignments and add to completed assignments
            active_assignments = volunteer_data.get('active_assignments', {})
            if request_id in active_assignments:
                active_assignments.pop(request_id)
                volunteer_ref.child('active_assignments').set(active_assignments)
                
                completed_assignments = volunteer_data.get('completed_assignments', {})
                completed_assignments[request_id] = {
                    "request_id": request_id,
                    "title": request_data.get('title'),
                    "completed_at": datetime.now(pytz.UTC).isoformat(),
                    "org_id": org_id
                }
                volunteer_ref.child('completed_assignments').set(completed_assignments)
        
        return jsonify({
            'success': True,
            'message': 'Request marked as completed!'
        })
        
    except Exception as e:
        logger.error(f"Error completing request: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500

if __name__ == '__main__':
    if not os.path.exists('instance'):
        os.makedirs('instance')
    app.run(debug=True)