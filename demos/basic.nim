import std / [os, strformat, math]
import nimdata
import boxy, opengl, windy

let windowSize = ivec2(1920, 1080)

let window = newWindow("Windy + Boxy", windowSize)
makeContextCurrent(window)

loadExtensions()

let bxy = newBoxy()

var frame: int

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
                    # .map(record => record.projectAway(date, Volume))
                    .cache()
# Called when it is time to draw a new frame.
proc display() =
  # Clear the screen and begin a new frame.
  bxy.beginFrame(windowSize)
  bxy.drawRect(rect(vec2(0, 0), window.size.vec2), color(1, 1, 1, 1))

  # bxy.saveTransform()
  let volumeHeight = 100
  let volumeWidth = windowSize[1]
  let kHeight = windowSize[1] - volumeHeight
  let image = newImage(windowSize[0], kHeight)
  let ctx = newContext(image)
  ctx.strokeStyle = "#dc5034"
  ctx.lineWidth = 1

  let ctx2 = newContext(image)
  ctx2.strokeStyle = "#508b37"
  ctx2.lineWidth = 1
  let df = getData()
  let min = df.map(record => record.Close).min()
  let max = df.map(record => record.Close).max()
  let h = df.map(record => record.High).max()
  let l = df.map(record => record.Low).min()
  let count = df.count()
  let dataset = df.collect()
  let gapWidth = 5
  let barWidth = floor((windowSize[0] - gapWidth * (count - 1) ) / count).int
  let offsetHigh = h - max
  let offsetLow = l - min
  
  let ratio = kHeight.float / (h - l)
  for i, record in dataset:
    let offsetX = i * (barWidth + gapWidth)
    let stickX = offsetX + barWidth div 2
    if record.Close > record.Open:
      let path = fmt"""
          M {offsetX} {(record.Close - l) * ratio}
          H {offsetX + barWidth}
          V {(record.Open - l) * ratio}
          H {offsetX}
          V {(record.Close - l) * ratio}
          Z
        """
      let
        start = vec2(stickX.float, (record.High - l) * ratio)
        stop = vec2(stickX.float, (record.Low - l) * ratio)

      ctx.strokeSegment(segment(start, stop))

      image.fillPath(
        path,
        rgba(220, 85, 62, 255)
      )
      
    elif record.Close < record.Open:
      let path = fmt"""
          M {offsetX} {(record.Open - l) * ratio}
          H {offsetX + barWidth}
          V {(record.Close - l) * ratio}
          H {offsetX}
          V {(record.Open - l) * ratio}
          Z
        """
      let
        start = vec2(stickX.float, (record.High - l) * ratio)
        stop = vec2(stickX.float, (record.Low - l) * ratio)

      ctx2.strokeSegment(segment(start, stop))

      image.fillPath(
        path,
        rgba(92, 149, 67, 255)
      )
      
    elif record.Close == record.Open:
      let path = fmt"""
          M {offsetX} {(record.Open - l) * ratio}
          H {offsetX + barWidth}
          V {(record.Close - l) * ratio}
          H {offsetX}
          V {(record.Open - l) * ratio}
          Z
        """

      image.fillPath(
        path,
        rgba(126, 126, 126, 255)
      )
  bxy.addImage("k", image)
  bxy.drawImage("k", rect = rect(vec2(0, 0), vec2(window.size.vec2[0].float32, kHeight.float32)))

  let image2 = newImage(volumeWidth, volumeHeight)
  let vMin = df.map(record => record.Volume).min()
  let vMax = df.map(record => record.Volume).max()
  let ratio2 = volumeHeight.float / vMax
  for i, record in dataset:
    let offsetX = i * (barWidth)
    let stickX = offsetX + barWidth div 2
    if record.Close > record.Open:
      let path = fmt"""
          M {offsetX} {volumeHeight}
          V {volumeHeight.float - record.Volume * ratio2}
          H {offsetX + barWidth}
          V {volumeHeight}
          H {offsetX}
          Z
        """
      image2.fillPath(
        path,
        rgba(220, 79, 52, 255)
      )
    elif record.Close < record.Open:
      let path = fmt"""
          M {offsetX} {volumeHeight}
          V {volumeHeight.float - record.Volume * ratio2}
          H {offsetX + barWidth}
          V {volumeHeight}
          H {offsetX}
          Z
        """

      image2.fillPath(
        path,
        rgba(80, 138, 55, 255)
      )

  bxy.addImage("v", image2)
  bxy.drawImage("v", rect = rect(vec2(0.float32, kHeight.float32),vec2(window.size.vec2[0].float32, volumeHeight.float32)))
  # bxy.restoreTransform()
  # End this frame, flushing the draw commands.
  bxy.endFrame()
  # Swap buffers displaying the new Boxy frame.
  window.swapBuffers()
  inc frame

while not window.closeRequested:
  display()
  pollEvents()