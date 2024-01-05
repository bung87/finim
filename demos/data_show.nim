import std/[os]
import nimdata


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
let df = dfRawText.map(schemaParser(schema, ','))
                  .map(record => record.projectAway(date, Volume))
                  .cache()
let min = df.map(record => record.Close).min()
let max = df.map(record => record.Close).max()
echo "Min : ", min
echo "Max : ", max
echo "Locator: ", (max - min) / 6
df.take(5).show()
