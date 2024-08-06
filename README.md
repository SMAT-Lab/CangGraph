### 基础用法——大模型的交互
```cj
import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*

main() {
  let llm = getLLMInstance(LLMType.OPEN_AI)

  println(llm.query("who are you?"))
  println(llm.query("translate what you have said into Chinese"))
}
```

## Node
在canggraph中，每个node都是一个可执行对象，可以是Agent，可以是Chain，可以是Tool
因此，每个node中都有一个runnable属性，该属性存储的是Runnable对象，agent，chain，tool都是Runnable的子类
在执行一个node的时候，只需要执行node.runnable.run()即可

### pythonREPL
```cj
import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*

main() {
    let llm = getLLMInstance(LLMType.OPEN_AI)


    let tool = pythonREPL()
    let args = Dict()
    args.put("code", """
def main():
    print('hello world')
""")
    args.put("filename","test")

    println(tool.invoke(args))
}
```

### 工具执行agent
```cj
import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*

main() {
    let llm = getLLMInstance(LLMType.OPEN_AI)
    let tools = ArrayList<BaseTool>([GetWeather(), pythonREPL()])

    let agent = create_openai_tools_agent(llm, tools)
    let input = Dict()
    input["input"] = "what is the weather like today in Guangzhou?"
    let res = agent.invoke(input)
    print(res)
}
```

### 自定义chain
```cj
import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*

main() {
    let llm = getLLMInstance(LLMType.OPEN_AI)
    let parameters = HashMap<String, Parameter>()
    let next: Parameter = Parameter("next", "String", true)
    parameters["next"] = next
    let function_def = BaseFunction("route", "Select the next role", parameters)
    let func_schema: JsonValue = get_function_schema(function_def)

    let tools = ArrayList<BaseTool>([GetWeather()])

    let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)
    chain.bind_function(func_schema)
    let members = ArrayList<String>(["Researcher", "Coder"])
    let options = members.append("FINISH")
    chain.add_prompt("system_message", 
      """
      You are a supervisor tasked with managing a conversation between the
      following workers: ${members}. Given the following user request,
      respond with the worker to act next. Each worker will perform a
      task and respond with their results and status. When finished,
      respond with FINISH.
      Given the conversation above, who should act next?
      Or should we FINISH? Select one of: ${options}
      Please call the tool to help you make the decision.
      """
    )
    let input = Dict()
    input["input"] = "What is the weather like today in Guangzhou?"
    let res = chain.invoke(input)
    println(res)
}
```

## Graph
```cangjie
import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*
from std import ffi.python.*

main() {
    // chain
    let llm = getLLMInstance(LLMType.OPEN_AI, model: "gpt-4o-mini")
    let parameters = HashMap<String, Parameter>()
    let next: Parameter = Parameter("Next", "The next role to act", true)
    parameters["next"] = next
    let function_def = BaseFunction("RouteDecider", "Select the next role to act", parameters)
    let func_schema: JsonValue = get_function_schema(function_def)

    let tools = ArrayList<BaseTool>([GetWeather()])

    let chain = CoTChain(llm, promptTemplate:SelfDefinePromptTemplate(), tools:tools)
    chain.bind_function(func_schema)
    let members = ArrayList<String>(["Researcher", "Coder", "Weather"])
    var options = members.clone()
    options.append("FINISH")
    chain.add_prompt("system_message", 
      """
      You are a supervisor tasked with managing a conversation between the
      following workers: ${members}. Given the following user request,
      respond with the worker to act next. Each worker will perform a
      task and respond with their results and status. When finished,
      respond with FINISH.
      Given the conversation above, who should act next?
      Or should we FINISH? Select one of: ${options}
      !!!You must call the tool 'RouteDecider' to help you make the decision. 
      """
    )

    let supervisor_node = Node("supervisor", "chain", chain)
    let input = Dict()
    input["input"] = "who should act next?"
    // let res = supervisor_node.run(input)
    // println(res)

    // tool
    let tool = pythonREPL()
    let input2 = Dict()
    input2.put("code", """
def main():
    print('hello world')
""")
    input2.put("filename","test")
    let tool_node = Node("pythonREPL", "tool", tool)
    // let res2 = tool_node.run(input2)
    // println(res2)

    // agent

    let agent = create_openai_tools_agent(llm, ArrayList<BaseTool>([GetWeather()]))

    let weather_agent = Node("Weather", "agent", agent)
    let input3 = Dict()
    input3.put("input", "what is the weather like today in Guangzhou?")
    // let res3 = weather_agent.run(input3)
    // println(res3)

    // graph
    let graph = Graph()
    graph.addNode(supervisor_node)
    graph.addNode(tool_node)
    graph.addNode(weather_agent)

    graph.setEntryPoint(supervisor_node)

    // graph.addEdge(supervisor_node, tool_node)
    graph.addEdge(tool_node, weather_agent)
    graph.addEdge(supervisor_node, weather_agent)
    graph.addEdge(weather_agent, supervisor_node)

    graph.setExitPoint(supervisor_node)

    graph.invoke(input3)
}
```

## tokenizer
```cangjie
from std import collection.*
from std import os.*
from std import os.posix.*
import titoken.*

main(): Int64 {
    var sentences:Array<String> =  ["苍穹是什么","苍穹"]
    //分词
    let tokenizer = Tokenizer(tokensFilePath: getcwd()+"/resource/tokenizer.json")
    let embedder = Embedder(modelPath: getcwd()+"/resource/embedding_model.onnx", tokensFilePath:getcwd()+"/resource/tokenizer.json")
    println("tokens: ${tokenizer(sentences)}")
    //计算词嵌入向量
    let sentence_embeddings = embedder(sentences)
    println("embedding: ${sentence_embeddings}")
    return 0 
}
```

## arkts代码修复
```cangjie
import llmapi.*
import graph.*
import tool.*
import agent.*
import schema.*
import chain.*
from std import collection.*
from encoding import json.*

main(): Int64 {
    var prompt = """
下面是我给出的一些代码缺陷修复demo：
缺陷修复demo_0:
规则:@performance/high-frequency-log-check
描述:不建议在高频函数中使用Hilog。

高频函数包括：onTouch、onItemDragMove、onDragMove、onMouse、onVisibleAreaChange、onAreaChange、onScroll、onActionUpdate。
问题代码:// Test.ets
import hilog from '@ohos.hilog';
@Entry
@Component
struct Index {
    build() {
            Column() {
                Scroll()
                    .onScroll(() => {
                        hilog.info(1001, 'Index', 'onScroll') // Avoid printing logs
                })
            }
    }
}
问题解释:在滚动组件中触发滚动属于高频事件，而 onScroll 函数会在每次滚动时被触发。如果在 onScroll 函数中使用 hilog.info 进行日志记录，就会导致每次滚动操作都进行一次日志记录，这样的高频操作会对性能造成负面影响。
问题修复:// Test.ets
@Entry
@Component
struct Index {
  build() {
      Column() {
        Scroll()
          .onScroll(() => {
            const TAG = 'onScroll';
          })
      }
  }
}

缺陷修复demo_1:
规则:@performance/hp-arkui-avoid-empty-callback
描述:避免设置空的系统回调监听。
问题代码:@Component
struct PositiveOfOnClick {
  build() {
    Button('Click', { type: ButtonType.Normal, stateEffect: true })
      .onClick(() => {
         // 无业务逻辑
    })
  }
} 
问题解释:在这个代码示例中，onClick 回调函数为空，没有任何业务逻辑。这会导致系统在每次点击按钮时都调用一个空函数，浪费系统资源，应当添加上业务逻辑。
问题修复:@Component
struct PositiveOfOnClick {
  build() {
    Button('Click', { type: ButtonType.Normal, stateEffect: true })
      .onClick(() => {
        // 业务逻辑
        dosomething()
    })
  }
} 

缺陷修复demo_2:
规则:@performance/hp-arkui-avoid-update-auto-state-var-in-aboutToReuse@performance/hp-arkui-avoid-update-auto-state-var-in-aboutToReuse
描述:避免在aboutToReuse中对自动更新值的状态变量进行更新。
问题代码:// 此处为复用的自定义组件
@Reusable
@Component
struct ChildComponent {
  @State desc: string = '';
  @State sum: number = 0;
  @ObjectLink avg: number = 0;

  aboutToReuse(params: Record<string, Object>): void {
    this.desc = params.desc as string;
    this.sum = params.sum as number;
    this.avg = params.avg as number;
  }
  build() {
    Column() {
      // 业务逻辑
    }
  }
}

@Entry
@Component
struct Reuse {
  private data: BasicDateSource = new BasicDateSource();

  aboutToAppear(): void {
    for (let index = 0; index < 20; index++) {
      this.data.pushData(index.toString())
    }
  }

  build() {
    Column() {
      List() {
        LazyForEach(this.data, (item: string) => {
          ListItem() {
            ChildComponent({ desc: item, sum: 0, avg: 0 })
          }
          .width('100%')
          .height(100)
        }, (item: string) => item)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
问题解释:aboutToReuse() 是组件复用时的回调函数，应当避免在此函数中对状态变量（如 desc、sum 和 avg）进行更新，特别是自动更新的状态变量。
问题修复:// 此处为复用的自定义组件
@Reusable
@Component
struct ChildComponent {
  @State desc: string = '';
  @State sum: number = 0;
  @State avg: number = 0;

  aboutToReuse(params: Record<string, Object>): void {
    this.desc = params.desc as string;
    this.sum = params.sum as number;
    this.avg = params.avg as number;
  }
  build() {
    Column() {
      // 业务逻辑
    }
  }
}

@Entry
@Component
struct Reuse {
  private data: BasicDateSource = new BasicDateSource();

  aboutToAppear(): void {
    for (let index = 0; index < 20; index++) {
      this.data.pushData(index.toString())
    }
  }

  build() {
    Column() {
      List() {
        LazyForEach(this.data, (item: string) => {
          ListItem() {
            ChildComponent({ desc: item, sum: 0, avg: 0 })
          }
          .width('100%')
          .height(100)
        }, (item: string) => item)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}

缺陷修复demo_3:
规则:@performance/hp-arkui-combine-same-arg-animateto

描述:建议动画参数相同时使用同一个animateTo。


问题代码:@Entry
@Component
struct MyComponent {
  @State textWidth: number = 200;
  @State color: Color = Color.Red;
  
  func1() {
    animateTo({ curve: Curve.Sharp, duration: 1000 }, () => {
      this.textWidth = (this.textWidth === 100 ? 200 : 100);
    });
  }
  
  func2() {
    animateTo({ curve: Curve.Sharp, duration: 1000 }, () => {
      this.color = (this.color === Color.Yellow ? Color.Red : Color.Yellow);
    });
  }
  
  build() {
    Column() {
      Row()
        .width(this.textWidth)
        .height(10)
        .backgroundColor(this.color)
      Text('click')
        .onClick(() => {
          this.func1();
          this.func2();
        })
    }
    .width('100%')
    .height('100%')
  }
}
问题解释:当多个动画参数相同时，建议使用同一个 animateTo 调用。问题代码中，func1() 和 func2() 分别使用了不同的 animateTo 调用，但它们的动画参数（curve 和 duration）相同。这样会导致在点击事件中两个动画独立执行，可能出现不协调的动画效果。通过将这两个动画合并到一个 animateTo 调用中，可以确保动画的统一性和协调性。
问题修复:@Entry
@Component
struct MyComponent {
  @State textWidth: number = 200;
  @State color: Color = Color.Red;
  
  func() {
    animateTo({ curve: Curve.Sharp, duration: 1000 }, () => {
      this.textWidth = (this.textWidth === 100 ? 200 : 100);
      this.color = (this.color === Color.Yellow ? Color.Red : Color.Yellow);
    });
  }
  
  build() {
    Column() {
      Row()
        .width(this.textWidth)
        .height(10)
        .backgroundColor(this.color)
      Text('click')
        .onClick(() => {
          this.func();
        })
    }
    .width('100%')
    .height('100%')
  }
}

缺陷修复demo_4:
规则:@performance/hp-arkui-load-on-demand

描述:建议使用按需加载。


问题代码:@Entry
@Component
struct MyComponent7 {
  @State arr: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]

  build() {
    List() {
      // List中建议使用LazyForEach
      ForEach(this.arr, (item: number) => {
        ListItem() {
          Text(`item value: \${item}`)
        }
      }, (item: number) => item.toString())
    }
    .height(100)
    .width(100)
  }
}
问题解释:nan
问题修复:class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []

  public totalCount(): number {
    return 0
  }

  public getData(index: number): string {
    return ''
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      console.info('add listener')
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      console.info('remove listener')
      this.listeners.splice(pos, 1)
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index)
    })
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index)
    })
  }

  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to)
    })
  }
}

class MyDataSource extends BasicDataSource {
  private dataArray: string[] = Array.from(Array<number>(10000), (v, k) => k.toString());

  public totalCount(): number {
    return this.dataArray.length
  }

  public getData(index: number): string  {
    return this.dataArray[index]
  }

  public addData(index: number, data: string): void {
    this.dataArray.splice(index, 0, data)
    this.notifyDataAdd(index)
  }

  public pushData(data: string): void {
    this.dataArray.push(data)
    this.notifyDataAdd(this.dataArray.length - 1)
  }
}

@Entry
@Component
struct MyComponent {
  private data: MyDataSource = new MyDataSource()

  build() {
    List() {
      LazyForEach(this.data, (item: string) => {
        ListItem() {
            Text(item).fontSize(20).margin({ left: 10 })
        }
      }, (item:string) => item)
    }
  }
}

请修复下面的代码缺陷:
```arkts
@Entry
@Component
struct MyComponent {
  @State mOpacity: number = 1;
  @State show: boolean = true;
  count: number = 0;

  build() {
    Column() {
      Row() {
        if (this.show) {
          Text('value')
            .opacity(this.mOpacity)
        }
      }
      .width('100%')
      .height(100)
      .justifyContent(FlexAlign.Center)
      Text('toggle state')
        .onClick(() => {
          this.count++;
          const thisCount: number = this.count;
          this.show = true;
      .height(100)
      .justifyContent(FlexAlign.Center)
      Text('toggle state')
        .onClick(() => {
          this.count++;
          const thisCount: number = this.count;
          this.show = true;
          animateTo({ duration: 1000, onFinish: () => {
            if (thisCount === this.count && this.mOpacity === 0) {
              this.show = false;
            }
          } }, () => {
            this.mOpacity = this.mOpacity === 1 ? 0 : 1;
          })
        })
    }
  }
}
```

"""
    let llm: OpenAI = (getLLMInstance(LLMType.OPEN_AI, model: "arktsLLM", chatUrl: Some("http://localhost:11434/v1")) as OpenAI).getOrThrow()
    let messages: ArrayList<JsonValue> = ArrayList<JsonValue>()
    let system_message: JsonObject = JsonObject()
    system_message.put("role", JsonString("system"))
    system_message.put("content", JsonString("You are an arkts code repair bot."))
    messages.append(system_message)

    let user_message: JsonObject = JsonObject()
    user_message.put("role", JsonString("user"))
    user_message.put("content", JsonString(prompt))
    messages.append(user_message)

    let res = llm.query(messages)
    println(res)

    return 0 
}
```