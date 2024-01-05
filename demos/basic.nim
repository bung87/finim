import std / [os, strformat, math]
import nimdata
import boxy, opengl, windy

let windowSize = ivec2(1920, 1080)

let window = newWindow("Windy + Boxy", windowSize)
makeContextCurrent(window)

loadExtensions()

let bxy = newBoxy()

# Load the images.
# bxy.addImage("bg", readImage("examples/data/bg.png"))
# bxy.addImage("ring1", readImage("examples/data/ring1.png"))
# bxy.addImage("ring2", readImage("examples/data/ring2.png"))
# bxy.addImage("ring3", readImage("examples/data/ring3.png"))

var frame: int

# Date	Open	High	Low	Close	Adj Close	Volume
# let ctx = newContext(image)
# ctx.fillStyle = rgba(255, 0, 0, 255)

# let
#   pos = vec2(50, 50)
#   wh = vec2(100, 100)

# ctx.fillRect(rect(pos, wh))


# let ctx = newContext(image)
# ctx.strokeStyle = "#FF5C00"
# ctx.lineWidth = 10

# let
#   start = vec2(25, 25)
#   stop = vec2(175, 175)

# ctx.strokeSegment(segment(start, stop))

proc getData(): auto =
  let dfRawText = DF.fromFile(currentSourcePath.parentDir / "AAPL.csv")
  const schema = [
    dateCol("date", format="yyyy-MM-dd"),
    floatCol("Open"),
    floatCol("High"),
    floatCol("Low"),
    floatCol("Close"),
    floatCol("Adj_Close"),
    floatCol("Volume"),
  ]
  result = dfRawText.map(schemaParser(schema, ','))
                    .map(record => record.projectAway(date, Volume))
                    .cache()
# Called when it is time to draw a new frame.
proc display() =
  # Clear the screen and begin a new frame.
  bxy.beginFrame(windowSize)
#   bxy.drawRect(rect(vec2(0, 0), window.size.vec2), color(255, 255, 255, 1))
  bxy.drawRect(rect(vec2(0, 0), window.size.vec2), color(1, 1, 1, 1))

  # bxy.saveTransform()
  let image = newImage(windowSize[0], windowSize[1])
  let df = getData()
  let min = df.map(record => record.Close).min()
  let max = df.map(record => record.Close).max()
  # let perH = windowSize[1] / (max - min)
  let count = df.count()
  let dataset = df.collect()
  let gapWidth = 2
  let barWidth = round((windowSize[0] - gapWidth * (count - 1) ) / count).int
  echo barWidth
  let ratio = windowSize[1].float / (max - min)
  for i, record in dataset:
    let isGrow = record.Close > record.Open
    let offsetX = i * barWidth + gapWidth
    if record.Close > record.Open:
      let path = fmt"""
          M {offsetX} {(record.Close - min) * ratio}
          H {offsetX + barWidth}
          V {(record.Open - min) * ratio}
          H {offsetX}
          V {(record.Close - min) * ratio}
          Z
        """

      image.fillPath(
        path,
        rgba(255, 0, 0, 255)
      )
    elif record.Close < record.Open:
      let path = fmt"""
          M {offsetX} {(record.Open - min) * ratio}
          H {offsetX + barWidth}
          V {(record.Close - min) * ratio}
          H {offsetX}
          V {(record.Open - min) * ratio}
          Z
        """

      image.fillPath(
        path,
        rgba(0, 255, 0, 255)
      )
    elif record.Close == record.Open:
      let path = fmt"""
          M {offsetX} {(record.Open - min) * ratio}
          H {offsetX + barWidth}
          V {(record.Close - min) * ratio}
          H {offsetX}
          V {(record.Open - min) * ratio}
          Z
        """

      image.fillPath(
        path,
        rgba(126, 126, 126, 255)
      )
  bxy.addImage("k", image)
  bxy.drawImage("k", rect = rect(vec2(0, 0), window.size.vec2))
  # bxy.restoreTransform()
  # End this frame, flushing the draw commands.
  bxy.endFrame()
  # Swap buffers displaying the new Boxy frame.
  window.swapBuffers()
  inc frame

while not window.closeRequested:
  display()
  pollEvents()