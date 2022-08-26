require "../../src/application"

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
