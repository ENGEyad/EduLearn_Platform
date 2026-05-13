/**
 * EduLearn Branch Management JS
 * Handles dynamic interactions for branch creation and permission management.
 */

document.addEventListener('DOMContentLoaded', function() {
    const branchListView = document.getElementById('branchListView');
    const branchFormView = document.getElementById('branchFormView');
    const openBranchFormBtn = document.getElementById('openBranchFormBtn');
    const backToBranchesBtn = document.getElementById('backToBranchesBtn');
    const cancelBranchBtn = document.getElementById('cancelBranchBtn');

    function showForm() {
        if (branchListView) branchListView.style.display = 'none';
        if (branchFormView) branchFormView.style.display = 'block';
    }

    function showList() {
        if (branchFormView) branchFormView.style.display = 'none';
        if (branchListView) branchListView.style.display = 'block';
    }

    if (openBranchFormBtn) openBranchFormBtn.addEventListener('click', showForm);
    if (backToBranchesBtn) backToBranchesBtn.addEventListener('click', showList);
    if (cancelBranchBtn) cancelBranchBtn.addEventListener('click', showList);

    // Password Generation Logic
    const generateBtn = document.getElementById('generatePasswordBtn');
    const passwordInput = document.getElementById('admin_password');

    if (generateBtn && passwordInput) {
        generateBtn.addEventListener('click', function() {
            const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*";
            let retVal = "";
            for (let i = 0, n = charset.length; i < 10; ++i) {
                retVal += charset.charAt(Math.floor(Math.random() * n));
            }
            passwordInput.value = retVal;
            
            // Pulse animation
            passwordInput.classList.add('pulse-light');
            setTimeout(() => passwordInput.classList.remove('pulse-light'), 1000);
        });
    }

    // 1. Branch Form Validation
    const branchForm = document.querySelector('form[action*="settings/branches"]');
    if (branchForm) {
        branchForm.addEventListener('submit', function(e) {
            // Add any custom validation here if needed
        });
    }

    // 2. Permission Toggle UX
    const permissionItems = document.querySelectorAll('.permission-item');
    permissionItems.forEach(item => {
        item.addEventListener('click', function(e) {
            // If the user clicked the div itself and not the checkbox/label
            if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'LABEL') {
                const checkbox = this.querySelector('input[type="checkbox"]');
                if (checkbox) {
                    checkbox.checked = !checkbox.checked;
                    
                    // Trigger change event for any listeners
                    const event = new Event('change', { bubbles: true });
                    checkbox.dispatchEvent(event);
                }
            }
        });
    });
});

/**
 * Global Helper for Confirmation Modals (using SweetAlert2 if available)
 */
window.confirmBranchAction = function(options) {
    if (typeof Swal !== 'undefined') {
        return Swal.fire({
            title: options.title || 'Are you sure?',
            text: options.text || 'This action cannot be undone.',
            icon: options.icon || 'warning',
            showCancelButton: true,
            confirmButtonColor: '#135bec',
            cancelButtonColor: '#94a3b8',
            confirmButtonText: options.confirmText || 'Confirm',
            cancelButtonText: options.cancelText || 'Cancel',
            background: '#ffffff',
            customClass: {
                title: 'fw-bold Cairo',
                confirmButton: 'px-4 py-2',
                cancelButton: 'px-4 py-2'
            }
        });
    } else {
        return Promise.resolve({ isConfirmed: confirm(options.text || 'Are you sure?') });
    }
};
