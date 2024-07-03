#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

typedef struct {
    char *response;
    size_t buffer_size;
} write_callback_data;

static size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    write_callback_data *data = (write_callback_data *)userp;
    size_t current_length = strlen(data->response);
    size_t available_space = data->buffer_size - current_length - 1;  // 预留1位给'\0'
    if (realsize > available_space) {
        realsize = available_space;
    }
    strncat(data->response, (char *)contents, realsize);
    return size * nmemb;
}



const char* serpapi_search(const char *url, const char *response, const size_t buffer_size) {
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
    if (!curl) {
        fprintf(stderr, "Unable to initialize curl.\n");
        return NULL;
    }
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        // curl_easy_setopt(curl, CURLOPT_POST, 1L);
        // curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
        write_callback_data callback_data = {response, buffer_size};
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &callback_data);
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
