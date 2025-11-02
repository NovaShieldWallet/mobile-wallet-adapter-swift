/**
 * Content script for Safari Web Extension
 * Injects Wallet Standard provider into web pages
 */

(function() {
    'use strict';
    
    // Inject provider script
    const script = document.createElement('script');
    script.src = safari.extension.baseURI + 'Resources/WalletStandardProvider.js';
    script.onload = function() {
        this.remove();
    };
    (document.head || document.documentElement).appendChild(script);
    
    // Listen for messages from injected script
    window.addEventListener('message', function(event) {
        if (event.source !== window || !event.data.type || event.data.type !== 'wallet_request') {
            return;
        }
        
        // Forward to extension background script
        safari.extension.dispatchMessage('wallet_request', event.data.request);
    });
    
    // Handle responses from background script
    safari.extension.addEventListener('message', function(event) {
        if (event.name === 'wallet_response') {
            // Forward response to injected script
            window.postMessage({
                type: 'wallet_response',
                response: event.message
            }, '*');
        }
    });
})();

