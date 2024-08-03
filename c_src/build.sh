# gcc api_request.c -fPIC -shared -lcurl -o ../lib/libapirequest.so
gcc api_request_multi.c -fPIC -shared -lcurl -o ../lib/libapirequest.so
gcc google_search.c -fPIC -shared -lcurl -o ../lib/libgooglesearch.so

gcc serpapi_search.c -fPIC -shared -lcurl -o ../lib/libserpapisearch.so
# gcc onnxruntime_cj_api.c onnx_runtime_wrapper.cc -fPIC -shared -lonnxruntime -o libonnxruntime_cj_api.so
# g++ -shared -fPIC  hnswlib.cpp -o libhnswlibcj.so
gcc onnx_runtime_wrapper.cc -std=c++11 -shared -fPIC -L-lonnxruntime -o ../lib/libonnxutils.so
apt-get install python3.9 python3.9-dev
gcc -fPIC -shared execute_python.c -o ../lib/libexecute_python.so $(python3.9-config --includes) -L/usr/lib/python3.9/config-3.9-x86_64-linux-gnu -lpython3.9
