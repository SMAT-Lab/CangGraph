## 能被agent调用的tool
自定义tools时，需要继承BaseTool类，并实现run方法，run方法的返回值为JsonObject类型。
需要设定参数args来方便后续使用大模型来进行调用。
Args类的构造函数为Args(name: string, description: string, required: bool)。
this.args = ArrayList<Args>([Args("filename", "filename to save", true), Args("content", "the content to be saved", true)])

## pythonREPL
还未完全实现，需要的是接收传入的python code，然后保存文件，再从文件中导入执行

## 版本

当前版本为0.1.0

当前适配的仓颉版本为0.39.4：

```
user@user-PC:~$ cjc -v
Cangjie Compiler: 0.39.4 (f479c5b39bbd 2023-06-27)
```

## 编译方法

编译并运行代码如下：

```
cjpm build
```

在Windows下如果输出中文结果为乱码，那么可以使用`chcp 65001`命令。

## 使用方法：

首先需要设置环境变量GOOGLE_API_KEY和SEARCH_ENGINE_ID，也可以在google_api_wrapper.cj源代码中自行设置：

- GOOGLE_API_KEY：Google API密钥，可以在[https://developers.google.com/custom-search/v1/introduction?apix=true&hl=zh-cn]()获取。

- SEARCH_ENGINE_ID：搜索引擎ID，可以在[https://www.google.com/cse/all]()获取。

通过GoogleSearchRun工具查询Google结果，关键字为“abc”：

```
let run = GoogleSearchRun()
println(run.name)
println(run.description)
var str = run.run("abc")
var results = (JsonValue.fromStr(str) as JsonObject).getOrThrow()
var items = (results.get("items").getOrThrow() as JsonArray).getOrThrow()
// 获取第一个查询结果
var item = (items.get(0).getOrThrow() as JsonObject).getOrThrow()
// 类型
var kind = (item.get("kind").getOrThrow() as JsonString).getOrThrow()
println(kind)
// 标题
var title = (item.get("title").getOrThrow() as JsonString).getOrThrow()
println(title)
// 链接
var link = (item.get("link").getOrThrow() as JsonString).getOrThrow()
println(link)
// 描述
var snippet = (item.get("snippet").getOrThrow() as JsonString).getOrThrow()
println(snippet)
```

通过GoogleSearchResults工具查询Google结果，关键字为“abc”：

```
let result = GoogleSearchResults()
let items = result.run("abc")
var item = (items.get(0).getOrThrow() as JsonObject).getOrThrow()
var kind = (item.get("kind").getOrThrow() as JsonString).getOrThrow()
println(kind)
var title = (item.get("title").getOrThrow() as JsonString).getOrThrow()
println(title)
var link = (item.get("link").getOrThrow() as JsonString).getOrThrow()
println(link)
var snippet = (item.get("snippet").getOrThrow() as JsonString).getOrThrow()
println(snippet)
```

输出结果类似如下：

```
"customsearch#result"
"ABC News - Breaking News, Latest News and Videos"
"https://abcnews.go.com/"
"Your trusted source for breaking news, analysis, exclusive interviews, headlines, and videos at ABCNews.com."
```

GoogleSearchRun可以返回整个Google搜索的结果，而GoogleSearchResult则是返回Google搜索的结果数组。

## 测试相关说明：

1. 准备工作
   测试脚本需要拉取 https://gitee.com/HW-PLLab/testJekins src下 ci_test 文件夹放入项目根目录下
   准备gitee_gate.cfg

2. 单元测试
   单元测试命令：
   `python3 ci_test/main.py build
   python3 ci_test/main.py test --ut`

3. LLT覆盖度测试
   gitee_gate.cfg 文件需修改 coverage 部分为 true

LLT覆盖度测试命令
`python3 ci_test/main.py build  --coverage
python3 ci_test/main.py test --coverage
cjcov --root=./ -e "./ci_test"  --html-details -o output`

> 覆盖度测试的源代码文件中不能有中文

## 参考

https://gitee.com/HW-PLLab/cangjie-library-pages/wikis/release%E8%A6%81%E6%B1%82
