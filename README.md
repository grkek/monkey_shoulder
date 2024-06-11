# Monkey Shoulder

Monkey Shoulder is a library for exposing functions over WebSockets asynchronously.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  monkey_shoulder:
    github: grkek/monkey_shoulder
```

## Usage

```crystal
require "monkey_shoulder/application"

class Mathematics < MonkeyShoulder::Binding
  @[Annotations::ExternalMethod]
  def add(a : Int32, b : Int32)
    a + b
  end

  @[Annotations::ExternalMethod]
  def subtract(a : Int32, b : Int32)
    a - b
  end

  @[Annotations::ExternalMethod]
  def multiply(a : Int32, b : Int32)
    a * b
  end

  @[Annotations::ExternalMethod]
  def divide(a : Int32, b : Int32)
    a / b
  end
end

Log.setup(:debug)

app = MonkeyShoulder::Application.new(host: "0.0.0.0", port: 4000)
app.run
```

Run the server and connect to it using a WebSocket client at 'ws://localhost:4000/ws/socket'

```json
{
    "eTag": "00000000-0000-0000-0000-000000000000",
    "body": {
        "instructionName": "listBindings"
    }
}
```

Send this payload to get all the bindnings, select the one above and use the ID below.

```json
{
    "eTag": "00000000-0000-0000-0000-000000000000",
    "body": {
        "id": "BINDING_ID",
        "instructionName": "executeMethod",
        "sourceCode": {
            "methodName": "multiply",
            "type": "EXTERNAL",
            "arguments": {"a": 1, "b": 2}
        }
    }
}
```

Send this payload to the server and it will return the result, you can use the eTag value to track responses from the server.


## Contributing

1. Fork it (<https://github.com/grkek/monkey_shoulder/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Giorgi Kavrelishvili](https://github.com/grkek) - creator and maintainer
