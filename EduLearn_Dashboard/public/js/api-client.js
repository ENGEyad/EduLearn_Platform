(function (window) {
    'use strict';

    if (!window) return;

    var rawBase = typeof window.API_BASE_URL === 'string' ? window.API_BASE_URL.trim() : '';
    var baseUrl = rawBase.replace(/\/+$/, '');
    var ABSOLUTE_URL_RE = /^[a-z][a-z\d+\-.]*:/i;

    function resolveUrl(endpoint) {
        if (typeof endpoint !== 'string' || endpoint.length === 0) return endpoint;
        if (ABSOLUTE_URL_RE.test(endpoint) || endpoint.startsWith('//')) return endpoint;
        if (!baseUrl) return endpoint;
        if (endpoint.startsWith('/')) return baseUrl + endpoint;
        return baseUrl + '/' + endpoint;
    }

    function withBaseUrl(input) {
        if (typeof input === 'string') return resolveUrl(input);
        if (typeof URL !== 'undefined' && input instanceof URL) return resolveUrl(input.toString());

        if (typeof Request !== 'undefined' && input instanceof Request) {
            var nextUrl = resolveUrl(input.url);
            if (nextUrl === input.url) return input;
            return new Request(nextUrl, input);
        }

        return input;
    }

    var nativeFetch = typeof window.fetch === 'function' ? window.fetch.bind(window) : null;

    function request(input, init) {
        if (!nativeFetch) throw new Error('window.fetch is not available in this browser.');
        return nativeFetch(withBaseUrl(input), init);
    }

    window.api = {
        baseUrl: baseUrl,
        resolveUrl: resolveUrl,
        request: request,
        fetch: request,
        get: function (endpoint, init) {
            return request(endpoint, Object.assign({}, init, { method: 'GET' }));
        },
        post: function (endpoint, body, init) {
            var options = Object.assign({}, init || {});
            options.method = 'POST';
            options.headers = Object.assign({ 'Content-Type': 'application/json' }, options.headers || {});
            options.body = JSON.stringify(body);
            return request(endpoint, options);
        },
        put: function (endpoint, body, init) {
            var options = Object.assign({}, init || {});
            options.method = 'PUT';
            options.headers = Object.assign({ 'Content-Type': 'application/json' }, options.headers || {});
            options.body = JSON.stringify(body);
            return request(endpoint, options);
        },
        patch: function (endpoint, body, init) {
            var options = Object.assign({}, init || {});
            options.method = 'PATCH';
            options.headers = Object.assign({ 'Content-Type': 'application/json' }, options.headers || {});
            options.body = JSON.stringify(body);
            return request(endpoint, options);
        },
        delete: function (endpoint, init) {
            return request(endpoint, Object.assign({}, init, { method: 'DELETE' }));
        }
    };

    window.apiFetch = request;

    if (nativeFetch) {
        window.fetch = function (input, init) {
            return request(input, init);
        };
    }
})(window);
