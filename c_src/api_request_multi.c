#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
volatile int g_stream_mode = 1;
volatile int g_stream_stop = 0;
int (*mycallback)(const char*);

void set_stream(int (*cb)(const char *)){
    g_stream_mode = 1;
    mycallback = cb;
}

void unset_stream(){
    g_stream_mode = 0;
}

static int count = 0;

static size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    char *response = (char *)userp;
    size_t realsize = size * nmemb;
    strncat(response, (char *)contents, realsize); 
    const char* content = strstr((char *)contents, "\"content\"");
    if (content != NULL){
        const char* start = strstr(content, ":\"");
        const char* end = strstr(content, "\"}");
        if(start != NULL && end != NULL && end > start){
            start += 2;
            char token[100] = {0};
            strncpy(token, start, end - start);
            char pre = ' ';
            char cur = ' ';
            for(int i=0;i < strlen(token);i++){
                cur = token[i];
                if(pre == '\\' && cur == 'n'){
                    printf("\n");
                } else if(pre == '\\' && cur == '\"'){
                    printf("\"");
                } else if(cur == '\\'){
                    pre = cur;
                    continue;
                } else {
                    printf("%c", cur);
                }
                pre = cur;
            }    
        }
    }
    return realsize;
}

int send_api_request(const char *url, const char *data, const char* response, size_t buffer_size, struct curl_slist *headers) {
    CURL *curl;
    CURLM *multi_handle;
    int still_running = 1; /* keep number of running handles */
    CURLMsg *msg; /* for picking up messages with the transfer status */
    int msgs_left; /* how many messages are left */

    if (response == NULL) {
        fprintf(stderr, "reponse buffer null.\n");
        return -1;
    }

    curl = curl_easy_init();
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, response);
        curl_easy_setopt(curl, CURLOPT_ENCODING, "");
        curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, 0); /* timeout per connection*/
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, 0); /* timeout of whole curl processing */

        multi_handle = curl_multi_init();
        curl_multi_add_handle(multi_handle, curl);

        while(still_running) {
            CURLMcode mcode = curl_multi_perform(multi_handle, &still_running);
            if(still_running){
                /* wait for activity, timeout or "nothing" */
                mcode = curl_multi_poll(multi_handle, NULL, 0, 1000, NULL);
            }

            if(mcode) {
                fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(mcode));
                curl_easy_cleanup(curl);
                return -1;
                break;
            }
        }

        /* See how the transfers went */
        while((msg = curl_multi_info_read(multi_handle, &msgs_left))) {
            if(msg->msg != CURLMSG_DONE) {
                // printf("HTTPS transfer completed with status %d\n", msg->data.result);
                continue;
            }
        }

        // if(g_stream_mode == 1 && g_stream_stop == 0) {
        //     printf("stream didn't stop\n");
        // }

        /* remove the transfers and cleanup the handles */
        curl_multi_remove_handle(multi_handle, curl);
        curl_easy_cleanup(curl);
        curl_multi_cleanup(multi_handle);
    }
    // printf("curl done\n");
    return 0;
}

struct curl_slist* create_curl_headers(const char* auth_header, const char* content_type, const char* accept_charset) {
    struct curl_slist* headers = NULL;
    headers = curl_slist_append(headers, auth_header);
    headers = curl_slist_append(headers, content_type);
    headers = curl_slist_append(headers, accept_charset);
    return headers;
}

const char* send_llm_request(const char* auth_header, const char* url, const char* response, size_t buffer_size, const char* data_content) {
    if (auth_header == NULL || url == NULL || response == NULL || data_content == NULL) {
        printf("memory null.");
        return NULL;
    }
    /* reponse buffer clear */
    memset(response, '\0', buffer_size);
    // Create custom headers with the Authorization header using the function
    const char* content_type = "Content-Type: application/json";
    const char* accept_charset = "Accept-Charset: utf-8";

    // Create custom headers
    struct curl_slist* headers = create_curl_headers(auth_header, content_type, accept_charset);

    // Send the API request with custom headers and formatted data
    send_api_request(url, data_content, response, buffer_size, headers);

    // Clean up
    curl_slist_free_all(headers);

    return response;
}

