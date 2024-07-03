#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

static size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    char *response = (char *)userp;
    strncat(response, (char *)contents, realsize);
    return realsize;
}

const char* search(const char *url, const char *response, const size_t buffer_size) {
    CURL *curl;
    CURLcode res;
    if (response == NULL) {
        fprintf(stderr, "Memory address null.\n");
        return NULL;
    } else {
        /* response buffer clear */
        memset(response, '\0', buffer_size);
    }
    const char* content_type = "Content-Type: application/json";
    const char* accept_charset = "Accept-Charset: utf-8";
    struct curl_slist* headers = NULL;
    headers = curl_slist_append(headers, content_type);
    headers = curl_slist_append(headers, accept_charset);
    
    curl = curl_easy_init();
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url);

        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        // curl_easy_setopt(curl, CURLOPT_POST, 1L);
        // curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, response);
        curl_easy_setopt(curl, CURLOPT_ENCODING, "");

        res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            response = NULL;
        }

        curl_easy_cleanup(curl);
    }
    return response;
}
