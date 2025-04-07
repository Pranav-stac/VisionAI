document.addEventListener('DOMContentLoaded', function() {
    // Enable all form controls
    const formInputs = document.querySelectorAll('input, textarea, select');
    formInputs.forEach(input => {
        input.removeAttribute('disabled');
    });

    // Initialize form validation
    const forms = document.querySelectorAll('.needs-validation');
    forms.forEach(form => {
        form.addEventListener('submit', function(event) {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        });
    });

    // Handle checkbox styling
    const checkboxes = document.querySelectorAll('.form-check-input[type="checkbox"]');
    checkboxes.forEach(checkbox => {
        checkbox.addEventListener('change', function() {
            this.classList.toggle('checked');
        });
    });

    // Ensure links are working
    document.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href && href !== '#' && !href.startsWith('javascript:')) {
                // Allow normal link behavior
                return true;
            }
        });
    });

    // Initialize floating labels
    const floatingInputs = document.querySelectorAll('.form-floating input');
    floatingInputs.forEach(input => {
        input.addEventListener('focus', () => {
            input.parentElement.classList.add('focused');
        });
        
        input.addEventListener('blur', () => {
            input.parentElement.classList.remove('focused');
        });
    });
    
    // Password confirmation validation
    const passwordField = document.getElementById('password');
    const confirmPasswordField = document.getElementById('confirm_password');
    
    if (passwordField && confirmPasswordField) {
        confirmPasswordField.addEventListener('input', function() {
            if (passwordField.value !== confirmPasswordField.value) {
                confirmPasswordField.setCustomValidity("Passwords don't match");
            } else {
                confirmPasswordField.setCustomValidity('');
            }
        });
        
        passwordField.addEventListener('input', function() {
            if (passwordField.value !== confirmPasswordField.value) {
                confirmPasswordField.setCustomValidity("Passwords don't match");
            } else {
                confirmPasswordField.setCustomValidity('');
            }
        });
    }
    
    // Password strength validation with visual indicator
    const passwordStrengthIndicator = document.querySelector('.password-strength-indicator');
    
    if (passwordField && passwordStrengthIndicator) {
        const strengthLevels = [
            { strength: 0, text: 'Very Weak', color: '#ff4b2b' },
            { strength: 1, text: 'Weak', color: '#ff7c45' },
            { strength: 2, text: 'Medium', color: '#ffc107' },
            { strength: 3, text: 'Strong', color: '#8bc34a' },
            { strength: 4, text: 'Very Strong', color: '#4CAF50' }
        ];
        
        passwordField.addEventListener('input', function() {
            const password = passwordField.value;
            let strength = 0;
            
            // Length check
            if (password.length >= 8) {
                strength += 1;
            }
            
            // Contains number check
            if (/\d/.test(password)) {
                strength += 1;
            }
            
            // Contains special character check
            if (/[^a-zA-Z0-9]/.test(password)) {
                strength += 1;
            }
            
            // Contains uppercase letter check
            if (/[A-Z]/.test(password)) {
                strength += 1;
            }
            
            // Update indicator
            const strengthInfo = strengthLevels[strength];
            const progressWidth = (strength / 4) * 100;
            
            passwordStrengthIndicator.innerHTML = `
                <div class="strength-text">${strengthInfo.text}</div>
                <div class="strength-progress">
                    <div class="strength-bar" style="width: ${progressWidth}%; background-color: ${strengthInfo.color}"></div>
                </div>
            `;
            
            // Update validity based on strength
            if (password.length > 0 && strength < 3) {
                passwordField.setCustomValidity('Password must be at least 8 characters long and include numbers, special characters, and uppercase letters');
            } else {
                passwordField.setCustomValidity('');
            }
        });
    } else if (passwordField) {
        // Original validation without visual indicator
        passwordField.addEventListener('input', function() {
            const password = passwordField.value;
            let strength = 0;
            
            // Length check
            if (password.length >= 8) {
                strength += 1;
            }
            
            // Contains number check
            if (/\d/.test(password)) {
                strength += 1;
            }
            
            // Contains special character check
            if (/[^a-zA-Z0-9]/.test(password)) {
                strength += 1;
            }
            
            // Contains uppercase letter check
            if (/[A-Z]/.test(password)) {
                strength += 1;
            }
            
            // Update validity based on strength
            if (password.length > 0 && strength < 3) {
                passwordField.setCustomValidity('Password must be at least 8 characters long and include numbers and special characters');
            } else {
                passwordField.setCustomValidity('');
            }
        });
    }
    
    // Enhanced animations for better scroll experience
    const animateOnScroll = function() {
        const elements = document.querySelectorAll('.slide-up, .fade-in, .zoom-in, .step-card, .category-card, .testimonial-card, .impact-item');
        
        elements.forEach(element => {
            const elementPosition = element.getBoundingClientRect().top;
            const screenPosition = window.innerHeight / 1.2;
            
            if (elementPosition < screenPosition) {
                // Get animation type based on class
                let animationType = 'fadeInUp';
                if (element.classList.contains('fade-in')) animationType = 'fadeIn';
                if (element.classList.contains('zoom-in')) animationType = 'zoomIn';
                if (element.classList.contains('slide-up')) animationType = 'fadeInUp';
                
                // Get delay attribute if exists
                const delay = element.getAttribute('data-delay') || 0;
                
                // Apply animation with delay
                setTimeout(() => {
                    if (!element.classList.contains('animated')) {
                        element.style.opacity = 1;
                        element.style.transform = 'none';
                        element.classList.add('animated');
                    }
                }, delay);
            }
        });
    };
    
    // Initialize animation
    window.addEventListener('scroll', animateOnScroll);
    animateOnScroll(); // Run once on load
    
    // Particle effect for hero section
    const heroSection = document.querySelector('.hero-section');
    if (heroSection) {
        createParticles(heroSection);
    }
    
    function createParticles(container) {
        const particlesContainer = document.createElement('div');
        particlesContainer.className = 'particles-container';
        particlesContainer.style.cssText = 'position: absolute; top: 0; left: 0; width: 100%; height: 100%; overflow: hidden; z-index: 1;';
        container.appendChild(particlesContainer);
        
        // Create particles
        for (let i = 0; i < 50; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            
            // Random size between 2-5px
            const size = Math.random() * 3 + 2;
            
            // Random position
            const xPos = Math.random() * 100;
            const yPos = Math.random() * 100;
            
            // Random opacity
            const opacity = Math.random() * 0.5 + 0.1;
            
            // Random animation duration
            const duration = Math.random() * 20 + 10;
            
            // Random animation delay
            const delay = Math.random() * 5;
            
            // Set styles
            particle.style.cssText = `
                position: absolute;
                width: ${size}px;
                height: ${size}px;
                background: white;
                border-radius: 50%;
                left: ${xPos}%;
                top: ${yPos}%;
                opacity: ${opacity};
                animation: particle-float ${duration}s ease-in-out infinite;
                animation-delay: ${delay}s;
                box-shadow: 0 0 10px ${opacity * 3}px rgba(255, 255, 255, 0.8);
            `;
            
            particlesContainer.appendChild(particle);
        }
        
        // Add keyframes for particle animation
        const style = document.createElement('style');
        style.innerHTML = `
            @keyframes particle-float {
                0%, 100% {
                    transform: translate(0, 0) rotate(0deg);
                }
                25% {
                    transform: translate(${Math.random() * 100 - 50}px, ${Math.random() * 100 - 50}px) rotate(90deg);
                }
                50% {
                    transform: translate(${Math.random() * 200 - 100}px, ${Math.random() * 200 - 100}px) rotate(180deg);
                }
                75% {
                    transform: translate(${Math.random() * 100 - 50}px, ${Math.random() * 100 - 50}px) rotate(270deg);
                }
            }
        `;
        document.head.appendChild(style);
    }
    
    // Handle filter dropdown for requests
    const filterDropdown = document.getElementById('filterDropdown');
    if (filterDropdown) {
        const dropdownItems = document.querySelectorAll('.dropdown-item');
        
        dropdownItems.forEach(item => {
            item.addEventListener('click', function(e) {
                e.preventDefault();
                
                // Remove active class from all items
                dropdownItems.forEach(i => i.classList.remove('active'));
                
                // Add active class to clicked item
                this.classList.add('active');
                
                // Update dropdown text
                filterDropdown.innerText = this.innerText;
                
                // Filter logic would go here
                const requestType = this.innerText.toLowerCase().replace(' ', '_');
                filterRequests(requestType);
            });
        });
    }
    
    // Function to filter requests
    function filterRequests(type) {
        const requestCards = document.querySelectorAll('.request-card');
        
        if (type === 'all_requests') {
            requestCards.forEach(card => {
                card.style.display = 'flex';
                setTimeout(() => card.style.opacity = 1, 10);
            });
            return;
        }
        
        requestCards.forEach(card => {
            const requestTypeElement = card.querySelector('.request-type');
            if (requestTypeElement.classList.contains('request-' + type.split('_')[0])) {
                card.style.display = 'flex';
                setTimeout(() => card.style.opacity = 1, 10);
            } else {
                card.style.opacity = 0;
                setTimeout(() => card.style.display = 'none', 300);
            }
        });
    }
    
    // Enhanced chat system in request details page
    const chatInput = document.querySelector('.chat-input input');
    const sendButton = document.querySelector('.send-button');
    const chatMessages = document.querySelector('.chat-messages');
    
    if (chatInput && sendButton && chatMessages) {
        sendButton.addEventListener('click', sendChatMessage);
        chatInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                sendChatMessage();
            }
        });
        
        // Add typing indicator
        const typingIndicator = document.createElement('div');
        typingIndicator.className = 'typing-indicator';
        typingIndicator.innerHTML = `
            <span></span>
            <span></span>
            <span></span>
        `;
        typingIndicator.style.display = 'none';
        chatMessages.appendChild(typingIndicator);
    }
    
    function sendChatMessage() {
        const message = chatInput.value.trim();
        if (message) {
            // Create message element
            const messageElement = document.createElement('div');
            messageElement.className = 'chat-message chat-message-sent';
            messageElement.innerHTML = `
                <div class="chat-bubble">
                    <p>${message}</p>
                    <span class="chat-time">${new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                </div>
            `;
            
            // Add to chat
            chatMessages.appendChild(messageElement);
            
            // Clear input
            chatInput.value = '';
            
            // Scroll to bottom
            chatMessages.scrollTop = chatMessages.scrollHeight;
            
            // Show typing indicator
            const typingIndicator = document.querySelector('.typing-indicator');
            if (typingIndicator) {
                typingIndicator.style.display = 'block';
                chatMessages.scrollTop = chatMessages.scrollHeight;
                
                // Simulate response (in real app, this would come from the server)
                setTimeout(() => {
                    typingIndicator.style.display = 'none';
                    
                    const responseElement = document.createElement('div');
                    responseElement.className = 'chat-message chat-message-received';
                    responseElement.innerHTML = `
                        <div class="chat-bubble">
                            <p>Thank you for your message. I'll get back to you shortly.</p>
                            <span class="chat-time">${new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                        </div>
                    `;
                    
                    chatMessages.appendChild(responseElement);
                    chatMessages.scrollTop = chatMessages.scrollHeight;
                }, 2000);
            }
        }
    }
    
    // Add parallax effect to elements
    window.addEventListener('scroll', function() {
        const parallaxElements = document.querySelectorAll('.parallax-effect');
        parallaxElements.forEach(element => {
            const scrollPosition = window.pageYOffset;
            const speed = element.getAttribute('data-speed') || 0.5;
            element.style.transform = `translateY(${scrollPosition * speed}px)`;
        });
    });
    
    // Add hover effects for cards
    const cards = document.querySelectorAll('.card, .category-card, .step-card, .testimonial-card, .profile-card, .request-card');
    cards.forEach(card => {
        card.addEventListener('mouseenter', function(e) {
            // Create a glowing effect
            const glow = document.createElement('div');
            glow.className = 'card-glow';
            glow.style.cssText = `
                position: absolute;
                width: 100%;
                height: 100%;
                top: 0;
                left: 0;
                background: radial-gradient(circle at ${e.offsetX}px ${e.offsetY}px, rgba(108, 99, 255, 0.2) 0%, transparent 70%);
                opacity: 0;
                z-index: 0;
                border-radius: inherit;
                transition: opacity 0.3s ease;
            `;
            
            if (!card.querySelector('.card-glow')) {
                card.style.position = 'relative';
                card.appendChild(glow);
                setTimeout(() => glow.style.opacity = 1, 10);
            }
        });
        
        card.addEventListener('mousemove', function(e) {
            const glow = card.querySelector('.card-glow');
            if (glow) {
                const x = e.offsetX;
                const y = e.offsetY;
                glow.style.background = `radial-gradient(circle at ${x}px ${y}px, rgba(108, 99, 255, 0.15) 0%, transparent 70%)`;
            }
        });
        
        card.addEventListener('mouseleave', function() {
            const glow = card.querySelector('.card-glow');
            if (glow) {
                glow.style.opacity = 0;
                setTimeout(() => glow && glow.remove(), 300);
            }
        });
    });
    
    // Add stunning counter animation in impact section
    const counterElements = document.querySelectorAll('.counter');
    if (counterElements.length > 0) {
        const counterObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const counter = entry.target;
                    const target = counter.innerText;
                    const isPlus = target.includes('+');
                    const numTarget = parseInt(target.replace(/\D/g, ''));
                    
                    let count = 0;
                    const duration = 2000; // 2 seconds
                    const frameRate = 1000 / 60; // 60fps
                    const totalFrames = duration / frameRate;
                    const increment = numTarget / totalFrames;
                    
                    counter.innerText = '0';
                    
                    const animate = () => {
                        count += increment;
                        if (count >= numTarget) {
                            count = numTarget;
                            counter.innerText = count + (isPlus ? '+' : '');
                            return;
                        }
                        counter.innerText = Math.floor(count) + (isPlus ? '+' : '');
                        requestAnimationFrame(animate);
                    };
                    
                    requestAnimationFrame(animate);
                    counterObserver.unobserve(counter);
                }
            });
        }, { threshold: 0.5 });
        
        counterElements.forEach(counter => {
            counterObserver.observe(counter);
        });
    }
    
    // Add dynamic shadow to navbar on scroll
    const navbar = document.querySelector('.navbar');
    if (navbar) {
        window.addEventListener('scroll', function() {
            if (window.scrollY > 30) {
                navbar.classList.add('navbar-shadow');
            } else {
                navbar.classList.remove('navbar-shadow');
            }
        });
    }
    
    // Add custom styles dynamically
    const dynamicStyles = `
        .navbar-shadow {
            box-shadow: 0 5px 25px rgba(0, 0, 0, 0.2);
        }
        
        .chat-message {
            margin-bottom: 15px;
            opacity: 0;
            transform: translateY(20px);
            animation: message-appear 0.3s forwards;
        }
        
        @keyframes message-appear {
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .chat-message-sent {
            text-align: right;
        }
        
        .chat-message-received {
            text-align: left;
        }
        
        .chat-bubble {
            display: inline-block;
            max-width: 80%;
            padding: 12px 18px;
            border-radius: 18px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            position: relative;
            z-index: 1;
        }
        
        .chat-message-sent .chat-bubble {
            background: linear-gradient(135deg, var(--primary), var(--primary-dark));
            color: var(--text-bright);
            border-bottom-right-radius: 4px;
        }
        
        .chat-message-sent .chat-bubble:before {
            content: '';
            position: absolute;
            bottom: 0;
            right: -10px;
            width: 20px;
            height: 20px;
            background: var(--primary-dark);
            border-bottom-left-radius: 15px;
            z-index: -1;
        }
        
        .chat-message-received .chat-bubble {
            background-color: var(--background-elevated);
            color: var(--text-primary);
            border-bottom-left-radius: 4px;
        }
        
        .chat-message-received .chat-bubble:before {
            content: '';
            position: absolute;
            bottom: 0;
            left: -10px;
            width: 20px;
            height: 20px;
            background: var(--background-elevated);
            border-bottom-right-radius: 15px;
            z-index: -1;
        }
        
        .chat-bubble p {
            margin-bottom: 5px;
        }
        
        .chat-time {
            font-size: 0.75rem;
            opacity: 0.7;
            display: block;
            text-align: right;
        }
        
        .typing-indicator {
            padding: 12px 18px;
            background-color: var(--background-elevated);
            border-radius: 18px;
            display: inline-flex;
            align-items: center;
            margin-bottom: 15px;
            position: relative;
        }
        
        .typing-indicator span {
            height: 8px;
            width: 8px;
            float: left;
            margin: 0 1px;
            background-color: var(--text-tertiary);
            display: block;
            border-radius: 50%;
            opacity: 0.4;
        }
        
        .typing-indicator span:nth-of-type(1) {
            animation: typing 1s infinite 0s;
        }
        
        .typing-indicator span:nth-of-type(2) {
            animation: typing 1s infinite 0.2s;
        }
        
        .typing-indicator span:nth-of-type(3) {
            animation: typing 1s infinite 0.4s;
        }
        
        @keyframes typing {
            0% {
                transform: translateY(0px);
                opacity: 0.4;
            }
            50% {
                transform: translateY(-5px);
                opacity: 0.8;
            }
            100% {
                transform: translateY(0px);
                opacity: 0.4;
            }
        }
        
        .strength-progress {
            height: 6px;
            background-color: rgba(255, 255, 255, 0.1);
            border-radius: 3px;
            margin-top: 5px;
            overflow: hidden;
        }
        
        .strength-bar {
            height: 100%;
            border-radius: 3px;
            transition: width 0.3s ease, background-color 0.3s ease;
        }
        
        .strength-text {
            font-size: 0.8rem;
            color: var(--text-secondary);
        }
        
        .animated {
            animation-fill-mode: both;
        }
    `;
    
    const style = document.createElement('style');
    style.textContent = dynamicStyles;
    document.head.appendChild(style);

    // Password strength validation
    const passwordInput = document.getElementById('password');
    const confirmPasswordInput = document.getElementById('confirmPassword');
    const strengthIndicator = document.querySelector('.password-strength');

    if (passwordInput) {
        passwordInput.addEventListener('input', function() {
            const strength = calculatePasswordStrength(this.value);
            updatePasswordStrengthUI(strength, strengthIndicator);
        });
    }

    if (confirmPasswordInput) {
        confirmPasswordInput.addEventListener('input', function() {
            if (this.value !== passwordInput.value) {
                this.setCustomValidity("Passwords don't match");
            } else {
                this.setCustomValidity('');
            }
        });
    }
});

// Password strength calculator
function calculatePasswordStrength(password) {
    let strength = 0;
    
    // Length check
    if (password.length >= 8) strength += 25;
    
    // Character type checks
    if (/[A-Z]/.test(password)) strength += 25;
    if (/[0-9]/.test(password)) strength += 25;
    if (/[^A-Za-z0-9]/.test(password)) strength += 25;
    
    return strength;
}

// Update password strength UI
function updatePasswordStrengthUI(strength, indicator) {
    if (!indicator) return;
    
    indicator.style.setProperty('--strength-width', `${strength}%`);
    
    let color;
    if (strength < 50) color = '#ff4757';
    else if (strength < 75) color = '#ffab00';
    else color = '#2ed573';
    
    indicator.style.setProperty('--strength-color', color);
}