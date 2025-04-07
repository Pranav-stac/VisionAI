// Dashboard functionality
document.addEventListener('DOMContentLoaded', function() {
    // Filter tabs functionality
    const filterTabs = document.querySelectorAll('.filter-tab');
    
    filterTabs.forEach(tab => {
        tab.addEventListener('click', function() {
            // Remove active class from all tabs
            filterTabs.forEach(t => t.classList.remove('active'));
            
            // Add active class to clicked tab
            this.classList.add('active');
            
            const filter = this.getAttribute('data-filter');
            filterRequests(filter);
        });
    });

    // Handle request acceptance
    window.acceptRequest = function(requestId) {
        if (!confirm('Are you sure you want to accept this request?')) {
            return;
        }

        // Find and disable the accept button
        const button = document.querySelector(`.request-card[data-request-id="${requestId}"] .btn-success`);
        if (button) {
            button.disabled = true;
            button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Accepting...';
        }

        // Make the API call
        fetch(`/accept-request/${requestId}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                // Find the request card
                const card = document.querySelector(`.request-card[data-request-id="${requestId}"]`);
                if (card) {
                    // Add acceptance animation
                    card.classList.add('request-accepted');
                    card.style.transform = 'translateX(100px)';
                    card.style.opacity = '0';
                    
                    // Remove card after animation
                    setTimeout(() => {
                        card.remove();
                        // Update counters
                        updateRequestCounters();
                    }, 500);

                    // Show success notification
                    showNotification('success', 'Request Accepted', 'You have successfully accepted this help request.');
                    
                    // Close modal if open
                    const modal = document.getElementById('requestDetailsModal');
                    if (modal) {
                        const bootstrapModal = bootstrap.Modal.getInstance(modal);
                        if (bootstrapModal) {
                            bootstrapModal.hide();
                        }
                    }
                }
            } else {
                // Reset button state on error
                if (button) {
                    button.disabled = false;
                    button.innerHTML = '<i class="fas fa-check"></i> Accept';
                }
                showNotification('error', 'Error', data.message || 'An error occurred while accepting the request.');
            }
        })
        .catch(error => {
            console.error('Error:', error);
            // Reset button state on error
            if (button) {
                button.disabled = false;
                button.innerHTML = '<i class="fas fa-check"></i> Accept';
            }
            showNotification('error', 'Error', 'An error occurred while accepting the request.');
        });
    };
    
    // Skill management
    const addSkillBtn = document.getElementById('addSkillBtn');
    if (addSkillBtn) {
        addSkillBtn.addEventListener('click', function() {
            const skillInput = document.getElementById('newSkill');
            const skill = skillInput.value.trim();
            
            if (skill) {
                fetch('/add-skill', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ skill: skill })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Add skill to UI
                        const skillsGrid = document.querySelector('.skills-grid');
                        const newSkill = document.createElement('span');
                        newSkill.className = 'skill-badge';
                        newSkill.textContent = skill;
                        skillsGrid.insertBefore(newSkill, skillsGrid.lastElementChild);
                        
                        // Clear input
                        skillInput.value = '';
                        
                        // Close modal
                        const modal = bootstrap.Modal.getInstance(document.getElementById('addSkillModal'));
                        modal.hide();
                        
                        showNotification('Skill added successfully!', 'success');
                    } else {
                        showNotification('Error adding skill: ' + data.message, 'error');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showNotification('Error adding skill. Please try again.', 'error');
                });
            }
        });
    }
    
    // Schedule management
    const addEventBtn = document.getElementById('addEventBtn');
    if (addEventBtn) {
        addEventBtn.addEventListener('click', function() {
            const eventTitle = document.getElementById('eventTitle').value.trim();
            const eventDate = document.getElementById('eventDate').value;
            const eventTime = document.getElementById('eventTime').value;
            
            if (eventTitle && eventDate && eventTime) {
                fetch('/add-event', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ 
                        title: eventTitle,
                        date: eventDate,
                        time: eventTime
                    })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Reload to show updated schedule
                        location.reload();
                    } else {
                        showNotification('Error adding event: ' + data.message, 'error');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showNotification('Error adding event. Please try again.', 'error');
                });
            }
        });
    }
    
    // Initialize any charts or special effects
    initializeCharts();
    initializeAnimations();

    // Add Firebase real-time listener for new requests
    initializeFirebaseListeners();
});

// Filter requests based on selected tab
function filterRequests(filter) {
    const tabs = document.querySelectorAll('.filter-tab');
    tabs.forEach(tab => tab.classList.remove('active'));
    event.currentTarget.classList.add('active');
    
    const requestCards = document.querySelectorAll('.request-card');
    
    requestCards.forEach(card => {
        const priority = card.dataset.priority;
        const distance = parseInt(card.dataset.distance) || Infinity;
        
        if (filter === 'all') {
            showCard(card);
        } else if (filter === 'urgent' && (priority === 'urgent' || priority === 'high')) {
            showCard(card);
        } else if (filter === 'nearby' && distance <= 10) {
            showCard(card);
        } else {
            hideCard(card);
        }
    });
}

function showCard(card) {
    card.style.display = '';
    // Use requestAnimationFrame for smooth animation
    requestAnimationFrame(() => {
        card.style.opacity = 1;
        card.style.transform = 'translateY(0)';
    });
}

function hideCard(card) {
    card.style.opacity = 0;
    card.style.transform = 'translateY(10px)';
    setTimeout(() => {
        card.style.display = 'none';
    }, 300);
}

// Show empty state when no requests are available
function showEmptyState() {
    const requestsContainer = document.querySelector('.requests-container');
    if (requestsContainer) {
        requestsContainer.innerHTML = `
            <div class="empty-state text-center">
                <div class="empty-state-icon">
                    <i class="fas fa-inbox"></i>
                </div>
                <h4>No Active Requests</h4>
                <p>There are currently no help requests available. Check back later!</p>
            </div>
        `;
    }
}

// Update helper statistics after accepting a request
function updateHelperStats() {
    const helpedCount = document.querySelector('.stat-helped .stat-value');
    if (helpedCount) {
        const currentCount = parseInt(helpedCount.textContent);
        helpedCount.textContent = currentCount + 1;
    }
}

// Show beautiful notifications
function showNotification(type, title, message) {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <div class="notification-icon">
            <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
        </div>
        <div class="notification-content">
            <h5>${title}</h5>
            <p>${message}</p>
        </div>
        <button class="notification-close">
            <i class="fas fa-times"></i>
        </button>
    `;
    
    document.body.appendChild(notification);
    
    // Show notification with animation
    setTimeout(() => {
        notification.classList.add('notification-show');
    }, 10);
    
    // Add close button functionality
    const closeBtn = notification.querySelector('.notification-close');
    closeBtn.addEventListener('click', () => {
        notification.classList.remove('notification-show');
        setTimeout(() => {
            notification.remove();
        }, 300);
    });
    
    // Auto hide after 5 seconds
    setTimeout(() => {
        if (document.body.contains(notification)) {
            notification.classList.remove('notification-show');
            setTimeout(() => {
                if (document.body.contains(notification)) {
                    notification.remove();
                }
            }, 300);
        }
    }, 5000);
}

// Initialize any charts
function initializeCharts() {
    // This would contain chart initialization code if needed
}

// Add beautiful animations
function initializeAnimations() {
    // Animate elements when they come into view
    const animatedElements = document.querySelectorAll('.animate-on-scroll');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animated');
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1 });
    
    animatedElements.forEach(el => observer.observe(el));
}

// Add this function to update request counters
function updateRequestCounters() {
    const helpRequestsCount = document.querySelector('.stat-card:nth-child(1) .stat-value');
    const urgentRequestsCount = document.querySelector('.stat-card:nth-child(2) .stat-value');
    const activeAssignmentsCount = document.querySelector('.stat-card:nth-child(3) .stat-value');

    if (helpRequestsCount) {
        const currentCount = parseInt(helpRequestsCount.textContent);
        helpRequestsCount.textContent = Math.max(0, currentCount - 1);
    }

    if (urgentRequestsCount) {
        const currentCount = parseInt(urgentRequestsCount.textContent);
        urgentRequestsCount.textContent = Math.max(0, currentCount - 1);
    }

    if (activeAssignmentsCount) {
        const currentCount = parseInt(activeAssignmentsCount.textContent);
        activeAssignmentsCount.textContent = currentCount + 1;
    }
}

function viewDetails(requestId) {
    const card = document.querySelector(`.request-card[data-request-id="${requestId}"]`);
    if (!card) return;

    // Remove any existing modal
    const existingModal = document.getElementById('requestDetailsModal');
    if (existingModal) {
        existingModal.remove();
    }

    const requestData = {
        title: card.querySelector('.request-title').textContent,
        priority: card.dataset.priority,
        description: card.querySelector('.request-description').textContent,
        location: card.querySelector('.meta-item.location').textContent.trim(),
        timing: card.querySelector('.meta-item.timing').textContent.trim()
    };

    const modalHtml = `
        <div class="modal fade request-details-modal" id="requestDetailsModal" tabindex="-1">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content">
                    <div class="request-details-header">
                        <h3 class="request-details-title">${requestData.title}</h3>
                        <div class="request-priority priority-${requestData.priority}">
                            ${requestData.priority.charAt(0).toUpperCase() + requestData.priority.slice(1)} Priority
                        </div>
                    </div>
                    
                    <div class="request-details-meta">
                        <div class="meta-card">
                            <div class="meta-icon" style="color: var(--vibrant-pink)">
                                <i class="fas fa-map-marker-alt"></i>
                            </div>
                            <div class="meta-info">
                                <h6>Location</h6>
                                <p>${requestData.location}</p>
                            </div>
                        </div>
                        
                        <div class="meta-card">
                            <div class="meta-icon" style="color: var(--vibrant-teal)">
                                <i class="fas fa-clock"></i>
                            </div>
                            <div class="meta-info">
                                <h6>Estimated Time</h6>
                                <p>${requestData.timing}</p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="request-details-description">
                        <h5>Description</h5>
                        <p>${requestData.description}</p>
                    </div>
                    
                    <div class="request-details-actions">
                        <button class="btn btn-outline-primary" data-bs-dismiss="modal">
                            <i class="fas fa-times"></i> Close
                        </button>
                        <button class="btn btn-success" onclick="acceptRequest('${requestId}')" data-request-id="${requestId}">
                            <i class="fas fa-check"></i> Accept Request
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;

    document.body.insertAdjacentHTML('beforeend', modalHtml);
    const modal = new bootstrap.Modal(document.getElementById('requestDetailsModal'));
    modal.show();
}

// Add this function to check for duplicates
function isRequestDuplicate(requestId) {
    return document.querySelectorAll(`.request-card[data-request-id="${requestId}"]`).length > 0;
}

// Update the addNewRequestCard function with better duplicate checking
function addNewRequestCard(requestId, request) {
    if (!requestId || !request) return;
    
    const requestsGrid = document.querySelector('.requests-grid');
    if (!requestsGrid) return;
    
    // Enhanced duplicate check
    if (isRequestDuplicate(requestId)) {
        console.log(`Duplicate request prevented: ${requestId}`);
        return;
    }
    
    const cardHtml = `
        <div class="request-card" 
             data-request-id="${requestId}" 
             data-priority="${request.priority}"
             data-timestamp="${Date.now()}">
            <div class="request-header">
                <h3 class="request-title">${request.title}</h3>
                <div class="request-priority priority-${request.priority}">
                    ${request.priority}
                </div>
            </div>
            
            <div class="request-body">
                <p class="request-description">${request.description}</p>
                <div class="request-meta">
                    <div class="meta-item location">
                        <i class="fas fa-map-marker-alt"></i>
                        ${request.location || 'Not specified'}
                    </div>
                    <div class="meta-item timing">
                        <i class="fas fa-clock"></i>
                        ${request.estimated_time || '30 mins'}
                    </div>
                </div>
            </div>
            
            <div class="request-actions">
                <button class="btn btn-primary" onclick="viewDetails('${requestId}')">
                    <i class="fas fa-info-circle"></i> View Details
                </button>
                <button class="btn btn-success" onclick="acceptRequest('${requestId}')" data-request-id="${requestId}">
                    <i class="fas fa-check"></i> Accept
                </button>
            </div>
        </div>
    `;
    
    // Insert at the beginning of the grid
    requestsGrid.insertAdjacentHTML('afterbegin', cardHtml);
    
    // Animate the new card
    const newCard = requestsGrid.firstElementChild;
    newCard.style.opacity = '0';
    newCard.style.transform = 'translateY(20px)';
    requestAnimationFrame(() => {
        newCard.style.opacity = '1';
        newCard.style.transform = 'translateY(0)';
    });
}

// Update the Firebase listener initialization
function initializeFirebaseListeners() {
    const helpRequestsRef = firebase.database().ref('help_requests');
    
    // Clear existing listeners
    helpRequestsRef.off();
    
    // Track processed requests
    const processedRequests = new Set();
    
    // Listen for new requests
    helpRequestsRef.on('child_added', (snapshot) => {
        const request = snapshot.val();
        const requestId = snapshot.key;
        
        // Check if we've already processed this request
        if (processedRequests.has(requestId) || isRequestDuplicate(requestId)) {
            return;
        }
        
        // Mark as processed
        processedRequests.add(requestId);
        
        // Show notification and popup for new requests
        showNotification('info', 'New Request', 'A new help request has been posted!');
        showNewRequestPopup(request, requestId);
        addNewRequestCard(requestId, request);
    });
    
    // Listen for removed requests
    helpRequestsRef.on('child_removed', (snapshot) => {
        const requestId = snapshot.key;
        const cards = document.querySelectorAll(`.request-card[data-request-id="${requestId}"]`);
        cards.forEach(card => {
            card.classList.add('request-accepted');
            setTimeout(() => card.remove(), 500);
        });
        // Remove from processed set
        processedRequests.delete(requestId);
    });
}

// Update the showNewRequestPopup function to include requestId
function showNewRequestPopup(request, requestId) {
    // Check for existing popup
    const existingPopup = document.querySelector(`.new-request-popup[data-request-id="${requestId}"]`);
    if (existingPopup) {
        existingPopup.remove();
    }
    
    const popupHtml = `
        <div class="new-request-popup" data-request-id="${requestId}">
            <div class="popup-header">
                <h4>New Help Request</h4>
                <span class="priority-badge priority-${request.priority}">${request.priority}</span>
            </div>
            <div class="popup-body">
                <h5>${request.title}</h5>
                <p>${request.description}</p>
                <div class="popup-meta">
                    <span><i class="fas fa-map-marker-alt"></i> ${request.location || 'Not specified'}</span>
                    <span><i class="fas fa-clock"></i> ${request.estimated_time || '30 mins'}</span>
                </div>
            </div>
            <div class="popup-actions">
                <button class="btn btn-sm btn-outline-primary" onclick="this.closest('.new-request-popup').remove()">
                    Dismiss
                </button>
                <button class="btn btn-sm btn-primary" onclick="viewDetails('${requestId}')">
                    View Details
                </button>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', popupHtml);
    
    // Auto-remove popup after 10 seconds
    setTimeout(() => {
        const popup = document.querySelector(`.new-request-popup[data-request-id="${requestId}"]`);
        if (popup) {
            popup.classList.add('fade-out');
            setTimeout(() => popup.remove(), 300);
        }
    }, 10000);
} 