from openai import OpenAI
client = OpenAI(
    base_url="https://api.xiaoai.plus/v1",
    api_key="sk-Y7BDSlT4EKjhVfPpA603Bb0cC549424b9d1734262f6fE6C0"
)
 
response = client.chat.completions.create(
  messages=[
    {
      "role": "system",
      "content": "Hello, how can I help you today?"
    },
    {
        "role": "user",
        "content": "What's the weather like in San Francisco"
    }
  ],
  model="gpt-4o",
  tools=[
    {
      "type": "function",
      "function": {
        "name": "get_current_temperature",
        "description": "Get the current temperature for a specific location",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {
              "type": "string",
              "description": "The city and state, e.g., San Francisco, CA"
            },
            "unit": {
              "type": "string",
              "enum": ["Celsius", "Fahrenheit"],
              "description": "The temperature unit to use. Infer this from the user's location."
            }
          },
          "required": ["location", "unit"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_rain_probability",
        "description": "Get the probability of rain for a specific location",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {
              "type": "string",
              "description": "The city and state, e.g., San Francisco, CA"
            }
          },
          "required": ["location"]
        }
      }
    }
  ]
)

print(response)