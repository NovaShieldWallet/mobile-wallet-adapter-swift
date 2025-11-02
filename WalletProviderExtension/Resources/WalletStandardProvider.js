/**
 * Wallet Standard Provider for Safari Web Extension
 * Injects into web pages to provide Solana wallet functionality
 */

(function() {
    'use strict';
    
    // Prevent multiple injections
    if (window.solana && window.solana._isInjected) {
        return;
    }
    
    // Wallet Standard provider implementation
    class WalletProvider {
        constructor() {
            this._isInjected = true;
            this._connected = false;
            this._publicKey = null;
            this._listeners = new Map();
        }
        
        get isConnected() {
            return this._connected;
        }
        
        get publicKey() {
            return this._publicKey;
        }
        
        // Connect to wallet
        async connect() {
            try {
                const response = await this._sendRequest('connect', {
                    origin: window.location.origin
                });
                
                this._connected = true;
                this._publicKey = response.publicKey;
                this._emit('connect', { publicKey: response.publicKey });
                
                return { publicKey: response.publicKey };
            } catch (error) {
                throw new Error(`Connection failed: ${error.message}`);
            }
        }
        
        // Disconnect
        async disconnect() {
            this._connected = false;
            this._publicKey = null;
            this._emit('disconnect');
        }
        
        // Sign transaction
        async signTransaction(transaction) {
            if (!this._connected) {
                throw new Error('Wallet not connected');
            }
            
            const txBytes = transaction.serialize().toString('base64');
            
            const response = await this._sendRequest('signTransaction', {
                origin: window.location.origin,
                tx: txBytes
            });
            
            const signature = Buffer.from(response.signature, 'base64');
            transaction.addSignature(this._publicKey, signature);
            
            return transaction;
        }
        
        // Sign message
        async signMessage(message) {
            if (!this._connected) {
                throw new Error('Wallet not connected');
            }
            
            const messageBytes = typeof message === 'string' 
                ? Buffer.from(message, 'utf8')
                : Buffer.from(message);
            
            const response = await this._sendRequest('signMessage', {
                origin: window.location.origin,
                message: messageBytes.toString('base64')
            });
            
            return {
                signature: Buffer.from(response.signature, 'base64'),
                publicKey: this._publicKey
            };
        }
        
        // Sign multiple transactions
        async signAllTransactions(transactions) {
            if (!this._connected) {
                throw new Error('Wallet not connected');
            }
            
            const txBytes = transactions.map(tx => tx.serialize().toString('base64'));
            
            const response = await this._sendRequest('signAllTransactions', {
                origin: window.location.origin,
                transactions: txBytes
            });
            
            // Add signatures to each transaction
            const signatures = response.signatures.map(sig => Buffer.from(sig, 'base64'));
            transactions.forEach((tx, i) => {
                if (signatures[i]) {
                    tx.addSignature(this._publicKey, signatures[i]);
                }
            });
            
            return transactions;
        }
        
        // Sign multiple messages
        async signAllMessages(messages) {
            if (!this._connected) {
                throw new Error('Wallet not connected');
            }
            
            const messageBytes = messages.map(msg => {
                const bytes = typeof msg === 'string' 
                    ? Buffer.from(msg, 'utf8')
                    : Buffer.from(msg);
                return bytes.toString('base64');
            });
            
            const response = await this._sendRequest('signAllMessages', {
                origin: window.location.origin,
                messages: messageBytes
            });
            
            const signatures = response.signatures.map(sig => Buffer.from(sig, 'base64'));
            return messages.map((msg, i) => ({
                message: typeof msg === 'string' ? Buffer.from(msg, 'utf8') : Buffer.from(msg),
                signature: signatures[i],
                publicKey: this._publicKey
            }));
        }
        
        // Send transaction (returns signed transaction bytes for dApp to broadcast)
        async sendTransaction(transaction) {
            if (!this._connected) {
                throw new Error('Wallet not connected');
            }
            
            // Sign the transaction
            const signedTx = await this.signTransaction(transaction);
            const signature = signedTx.signatures[0].signature.toString('base64');
            
            // Request sendTransaction - returns full signed transaction bytes
            const response = await this._sendRequest('sendTransaction', {
                origin: window.location.origin,
                txHash: signature
            });
            
            // Return transaction signature (dApp will submit to RPC)
            // Note: response.signature contains full signed transaction bytes if needed
            return signature;
        }
        
        // Event listeners
        on(event, callback) {
            if (!this._listeners.has(event)) {
                this._listeners.set(event, []);
            }
            this._listeners.get(event).push(callback);
        }
        
        removeListener(event, callback) {
            const listeners = this._listeners.get(event);
            if (listeners) {
                const index = listeners.indexOf(callback);
                if (index > -1) {
                    listeners.splice(index, 1);
                }
            }
        }
        
        _emit(event, data) {
            const listeners = this._listeners.get(event) || [];
            listeners.forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error('Error in wallet event listener:', error);
                }
            });
        }
        
        // Send request to native app via Safari extension
        async _sendRequest(method, params) {
            return new Promise((resolve, reject) => {
                const requestId = Date.now() + Math.random();
                
                const request = {
                    jsonrpc: '2.0',
                    id: requestId,
                    method: method,
                    params: params
                };
                
                // Communicate with extension background script
                // In a real implementation, this would use Safari Web Extension messaging
                if (typeof safari !== 'undefined' && safari.extension) {
                    safari.extension.dispatchMessage('wallet_request', request, (response) => {
                        if (response.error) {
                            reject(new Error(response.error.message));
                        } else {
                            resolve(response.result);
                        }
                    });
                } else {
                    // Fallback: store in App Group and post notification
                    // Extension background script will handle
                    const message = {
                        type: 'wallet_request',
                        request: request
                    };
                    
                    // Store in shared storage (App Group)
                    // This is a simplified version - real implementation uses App Groups
                    window.localStorage.setItem(`wallet_request_${requestId}`, JSON.stringify(message));
                    
                    // Trigger native app via custom URL scheme
                    window.location.href = `walletapp://request?id=${requestId}`;
                    
                    // Poll for response (simplified - use proper messaging in production)
                    const pollInterval = setInterval(() => {
                        const responseKey = `wallet_response_${requestId}`;
                        const response = window.localStorage.getItem(responseKey);
                        if (response) {
                            clearInterval(pollInterval);
                            window.localStorage.removeItem(responseKey);
                            
                            const parsed = JSON.parse(response);
                            if (parsed.error) {
                                reject(new Error(parsed.error.message));
                            } else {
                                resolve(parsed.result);
                            }
                        }
                    }, 100);
                    
                    // Timeout after 30 seconds
                    setTimeout(() => {
                        clearInterval(pollInterval);
                        reject(new Error('Request timeout'));
                    }, 30000);
                }
            });
        }
    }
    
    // Inject provider into window
    const provider = new WalletProvider();
    window.solana = provider;
    
    // Also register with Wallet Standard if available
    if (window.navigator && window.navigator.wallets) {
        window.navigator.wallets.push(provider);
    }
    
    console.log('Wallet Standard provider injected');
})();

