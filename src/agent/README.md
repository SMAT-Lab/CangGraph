# 源码目录
```
├── README.md
├── agent.cj
├── simple_react_agent.cj
```

# 基本概念

- **Agent**: Agent 是目前学术界与工业界常用的一种使 LLM 与各种工具相结合的范式。它在 Chain 的基础上提供了更灵活地调用 LLMs 与其他工具(Tools)的接口，并运用逐次询问的方法来完成一个给定的任务，或回答一个给定的问题。
- **ReAct**: 一种典型的 Agent。提出于 https://arxiv.org/abs/2210.03629 规定了询问使用的 Prompt 与调用工具的格式，并使用 In-context Learning 的方式进行运作。它的运行过程大致如下所示：

    ```plaintext
    I need to find out who Leo DiCaprio's girlfriend is and then calculate her age raised to the 0.43 power.
    Action: Search
    Action Input: "Leo DiCaprio girlfriend"
    Observation: Camila Morrone
    Thought: I need to find out Camila Morrone's age
    Action: Search
    Action Input: "Camila Morrone age"
    Observation: 25 years
    Thought: I need to calculate 25 raised to the 0.43 power
    Action: Calculator
    Action Input: 25^0.43
    Observation: Answer: 3.991298452658078

    Thought: I now know the final answer
    Final Answer: Camila Morrone is Leo DiCaprio's girlfriend and her current age raised to the 0.43 power is 3.991298452658078.
    ```
    
- **Planner**: Agent 的核心 LLM。由于其承担的职责大致为计划如何完成问题、如何调用工具，故通常被命名为 Planner。

# 接口文档

## 文件：agent.cj

1. `AgentAction`: Planner 返回的内容解析得到的下级结构体。包含 Planner 想要调用的工具的名称、调用参数、与工具实际调用的返回值（工具调用前为空）。
2. `AgentOutput`: Planner 返回的内容解析得到的枚举类型，用以判断 Planner 是想要调用单个工具(Action)，多个工具(Actions)，还是判断问题已成功回答(Finish)。Finish 携带的字符串为该问题的最终答案。
3. `ActionExecutor`: 表征执行 Action 能力（即调用工具能力）的接口。Agent 应具备此能力。
4. `BaseAgent`: Agent 的抽象基类，仅实现了 Agent 的调用工具部分。未实现 `Chain` 类的 `generate` 方法。
5. `StepResult`: Planner 返回的内容解析到的上级结构体，包含了 `AgentOutput` 和 `log`，其中 `log` 记录了 Planner 的原始返回结果。 
6. `Agent`: Agent 的 (High-level) 抽象基类。基本遵循类 ReAct 的 Action Agent 范式实现了分步调用工具的流程。未实现 `constructAgentScratchPad` 方法。

## 文件：simple_react_agent.cj

1. `SimpleReActPromptTemplate`: 从输入的 `HashMap` 中提取字段填入 ReAct 使用的 Prompt 中。
2. `SimpleReActChain`: 对 `SimpleReActPromptTemplate` 与 `ChatGPT` 的简单包装。
3. `ReActAgent`: 开箱即用的基于 ReAct 范式的 Agent。

## 文件：react_agent.cj  **新增**
1. 真正地实现了react_agent的工具调用： 目前仅实现了get_weather工具的交互，其它工具请参考tool/README.md以及tool/get_weather.cj的实现

## Multi-Agent
目前粗略写了code_reviewer, code_tester, code_writer, doc_writer四个agent，这四个agent目前还没有实现工具，仅使用了prompt
planner.cj类为multi-agent的调用类，输入一个任务，planner可以自由选择一个agent去进行任务。目前的选择逻辑较为粗糙，后续可以参考react_agent进行重写

# 使用示例

```
main() {
    let agent = ReActAgent(ArrayList<Tool>([MockTool()]))
    let response = agent.predict("I need to find out who Leo DiCaprio's girlfriend is and then calculate her age raised to the 0.43 power.")
    println(response["text"])
}
```

multi-agent:
```
import llmapi.*
import agent.*
import tool.*
from std import collection.*
from encoding import json.*

main() {
    let docWriter = DocWriterAgent()
    let codeWriter = CodeWriterAgent()
    let codeReviewer = CodeReviewerAgent()
    let codeTester = CodeTesterAgent()

    let planner = PlannerAgent(agents: ArrayList<Role>([docWriter, codeWriter, codeReviewer, codeTester]))
    let plan = planner.generate("写一个程序，接收一个四则运算式子，输出计算结果。")
    println(plan)
    
}
```