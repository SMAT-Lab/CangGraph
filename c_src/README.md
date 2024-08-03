# 编译说明
## 准备
```shell
sudo apt-get install libcurl-dev  (ubuntu 18.04)
sudo apt-get install libcurl4-openssl-dev (ubuntu 22.04)
sudo apt-get install python3.8 python3.8-dev

```

## 编译
```shell
gcc api_request_multi.c -fPIC -shared -lcurl -o libapirequest.so
gcc google_search.c -fPIC -shared -lcurl -o libgooglesearch.so
gcc -fPIC -shared execute_python.c -o libexecute_python.so $(python3.8-config --includes) -L/usr/lib/python3.8/config-3.8-x86_64-linux-gnu -lpython3.8
```

## so存放
`*.so`存放在cangchain/lib/